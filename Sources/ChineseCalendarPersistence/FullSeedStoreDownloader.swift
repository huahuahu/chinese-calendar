import ChineseCalendarLogging
import Foundation
import Synchronization

/// 边接收边写入持久片段，进度只统计已写入文件的字节，不依赖 Content-Length。
final class FullSeedStoreDownloader: NSObject, URLSessionDataDelegate {
    private struct State {
        var task: URLSessionDataTask?
        var continuation: CheckedContinuation<Void, Error>?
        var fileHandle: FileHandle?
        var downloadedByteCount: Int64 = 0
        var failure: Error?
        var isCancelled = false
    }

    private let partialURL: URL
    private let expectedByteCount: Int64
    private let requestedOffset: Int64
    private let progressHandler: @Sendable (Double) -> Void
    private let state = Mutex(State())

    /// 片段路径由清单摘要确定，重建下载器后仍能找到同一份文件。
    init(
        partialURL: URL,
        expectedByteCount: Int64,
        requestedOffset: Int64,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) {
        self.partialURL = partialURL
        self.expectedByteCount = expectedByteCount
        self.requestedOffset = requestedOffset
        self.progressHandler = progressHandler
    }

    /// 桥接分块数据回调；取消后等文件关闭、网络任务结束，才返回调用方。
    func download(for request: URLRequest, using session: URLSession) async throws {
        let task = session.dataTask(with: request)
        task.delegate = self
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let shouldStart = state.withLock { state in
                    guard !state.isCancelled else { return false }
                    state.continuation = continuation
                    state.task = task
                    return true
                }
                if shouldStart {
                    task.resume()
                } else {
                    task.cancel()
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let activeTask = self.state.withLock { state in
                state.isCancelled = true
                return state.task
            }
            activeTask?.cancel()
        }
    }

    /// 先验证状态码和续传范围，再打开文件，避免把错误页或错误区段拼进去。
    func urlSession(
        _: URLSession,
        dataTask _: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        state.withLock { state in
            guard !state.isCancelled else { return .cancel }
            do {
                let offset = try validatedOffset(for: response)
                state.fileHandle = try openPartialFile(at: offset)
                state.downloadedByteCount = offset
                return .allow
            } catch {
                state.failure = error
                return .cancel
            }
        }
    }

    /// 每块数据写入成功后才更新进度；杀进程不依赖取消回调来保存片段。
    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            let fraction = try state.withLock { state -> Double? in
                guard !state.isCancelled, state.failure == nil, let handle = state.fileHandle else { return nil }
                guard Int64(data.count) <= expectedByteCount - state.downloadedByteCount else {
                    throw ChineseCalendarFullSeedStoreInstallError.invalidByteCount(
                        expected: expectedByteCount, actual: state.downloadedByteCount + Int64(data.count)
                    )
                }
                try handle.write(contentsOf: data)
                state.downloadedByteCount += Int64(data.count)
                return Double(state.downloadedByteCount) / Double(expectedByteCount)
            }
            if let fraction {
                progressHandler(fraction)
            }
        } catch {
            state.withLock { $0.failure = error }
            dataTask.cancel()
        }
    }

    /// 关闭文件后仅恢复一次 continuation；失败或取消也保留已有片段。
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        let completion = state.withLock { state in
            var failure = state.failure ?? (state.isCancelled ? CancellationError() : error)
            do {
                try state.fileHandle?.close()
            } catch {
                failure = failure ?? error
            }
            state.fileHandle = nil
            if failure == nil, state.downloadedByteCount != expectedByteCount {
                failure = ChineseCalendarFullSeedStoreInstallError.invalidByteCount(
                    expected: expectedByteCount, actual: state.downloadedByteCount
                )
            }
            let continuation = state.continuation
            state.continuation = nil
            state.task = nil
            return (continuation, failure)
        }
        if let error = completion.1 {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                ChineseCalendarLog.persistence.info("Full seed store transfer cancelled")
            } else {
                ChineseCalendarLog.persistence.error("Full seed store transfer failed: \(error.localizedDescription)")
            }
            completion.0?.resume(throwing: error)
        } else {
            let completedByteCount = expectedByteCount
            ChineseCalendarLog.persistence.info("Full seed store transfer completed: \(completedByteCount) bytes")
            completion.0?.resume()
        }
    }
}

private extension FullSeedStoreDownloader {
    /// 206 必须精确对应请求的剩余范围；200 表示服务器要求从头接收。
    func validatedOffset(for response: URLResponse) throws -> Int64 {
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        switch response.statusCode {
        case 200:
            if requestedOffset > 0 {
                ChineseCalendarLog.persistence.notice("Server ignored Range; restarting full seed store download")
            }
            return 0
        case 206:
            let expectedRange = "bytes \(requestedOffset)-\(expectedByteCount - 1)/\(expectedByteCount)"
            guard response.value(forHTTPHeaderField: "Content-Range") == expectedRange else {
                throw ChineseCalendarFullSeedStoreInstallError.invalidContentRange
            }
            let resumeOffset = requestedOffset
            ChineseCalendarLog.persistence.info("Server accepted full seed store resume at byte \(resumeOffset)")
            return requestedOffset
        case 416:
            // 只报告偏移无效；等请求结束、文件关闭后由安装器清理并重试。
            throw ChineseCalendarFullSeedStoreInstallError.rangeNotSatisfiable
        default:
            throw ChineseCalendarFullSeedStoreInstallError.downloadFailed(response.statusCode)
        }
    }

    /// 服务器接受续传时追加；忽略 Range 时先截断，避免新旧内容重复。
    func openPartialFile(at offset: Int64) throws -> FileHandle {
        // 仅在本次同步调用中使用，不让非 Sendable 实例跨回调共享。
        let fileManager = FileManager()
        if !fileManager.fileExists(atPath: partialURL.path) {
            guard fileManager.createFile(atPath: partialURL.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: partialURL)
        do {
            if offset == 0 {
                try handle.truncate(atOffset: 0)
            }
            guard try handle.seekToEnd() == UInt64(offset) else {
                throw ChineseCalendarFullSeedStoreInstallError.invalidContentRange
            }
            return handle
        } catch {
            try? handle.close()
            throw error
        }
    }
}
