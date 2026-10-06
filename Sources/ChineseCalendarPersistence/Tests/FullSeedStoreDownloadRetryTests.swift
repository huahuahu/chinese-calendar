@testable import ChineseCalendarPersistence
import Foundation
import Synchronization
import Testing

extension FullSeedStoreDownloadTests {
    @Test func rejectedOffsetDiscardsPartialAndRetriesWithoutRange() async throws {
        let fixture = try Fixture(statusCode: 416, existingChunks: 2)
        defer { fixture.cleanUp() }
        // 使用不同内容，确认重试没有把旧片段拼入完整响应。
        try Data(repeating: 99, count: Self.chunkSize * 2).write(to: fixture.partialURL)
        let retry = fixture.enqueueResponse(statusCode: 200)
        fixture.response.remainder.continuation.finish()
        retry.remainder.continuation.finish()
        let transfer = fixture.start()

        #expect(try await Data(contentsOf: transfer.task.value) == Self.body)
        #expect(fixture.requests.map { $0.value(forHTTPHeaderField: "Range") } == ["bytes=\(Self.chunkSize * 2)-", nil])
        #expect(transfer.fractions.values.withLock { Array($0.prefix(2)) } == [0.5, 0])
    }

    @Test(arguments: [206, 416])
    func invalidRangeOnRetryDoesNotStartAThirdRequest(statusCode: Int) async throws {
        let fixture = try Fixture(statusCode: statusCode, existingChunks: 1, contentRange: "invalid")
        defer { fixture.cleanUp() }
        let retry = fixture.enqueueResponse(statusCode: statusCode, contentRange: "invalid")
        let unexpectedThird = fixture.enqueueResponse(statusCode: 200)
        fixture.response.remainder.continuation.finish()
        retry.remainder.continuation.finish()
        unexpectedThird.remainder.continuation.finish()
        let transfer = fixture.start()

        await #expect(throws: ChineseCalendarFullSeedStoreInstallError.self) {
            try await transfer.task.value
        }
        #expect(fixture.requests.map { $0.value(forHTTPHeaderField: "Range") } == ["bytes=\(Self.chunkSize)-", nil])
        #expect(!unexpectedThird.observations.withLock { $0.started })
        #expect(!FileManager.default.fileExists(atPath: fixture.partialURL.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.destinationURL.path))
    }

    @Test(arguments: [206, 416])
    func invalidRangeWithoutExistingPartialDoesNotRetry(statusCode: Int) async throws {
        let fixture = try Fixture(statusCode: statusCode, contentRange: "invalid")
        defer { fixture.cleanUp() }
        fixture.response.remainder.continuation.finish()
        let transfer = fixture.start()

        await #expect(throws: ChineseCalendarFullSeedStoreInstallError.self) {
            try await transfer.task.value
        }
        #expect(fixture.requests.count == 1)
        #expect(fixture.requests.first?.value(forHTTPHeaderField: "Range") == nil)
    }

    @Test(arguments: [206, 416])
    func failedPartialRemovalIsReportedWithoutRetry(statusCode: Int) async throws {
        let fixture = try Fixture(statusCode: statusCode, existingChunks: 1, contentRange: "invalid")
        defer { fixture.cleanUp() }
        let retry = fixture.enqueueResponse(statusCode: 200)
        fixture.response.remainder.continuation.finish()
        retry.remainder.continuation.finish()
        let fileManager = RemovalFailingFileManager()
        let transfer = fixture.start(fileManager: fileManager)

        do {
            _ = try await transfer.task.value
            Issue.record("Download retried despite failing to remove the old partial")
        } catch let error as CocoaError {
            #expect(error.code == .fileWriteNoPermission)
        }
        #expect(fileManager.removalAttempts.withLock { $0 } == 1)
        #expect(fixture.requests.count == 1)
        #expect(!retry.observations.withLock { $0.started })
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize))
        #expect(transfer.fractions.values.withLock { $0 } == [0.25])
    }

    @Test func invalidPartialSizeRemovalFailureStopsBeforeRequest() async throws {
        let fixture = try Fixture(existingChunks: 1, expectedByteCount: 1)
        defer { fixture.cleanUp() }
        let fileManager = RemovalFailingFileManager()
        let transfer = fixture.start(fileManager: fileManager)

        do {
            _ = try await transfer.task.value
            Issue.record("Download started despite failing to remove an oversized partial")
        } catch let error as CocoaError {
            #expect(error.code == .fileWriteNoPermission)
        }
        #expect(fileManager.removalAttempts.withLock { $0 } == 1)
        #expect(fixture.requests.isEmpty)
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize))
    }

    @Test(arguments: [URLError.Code.networkConnectionLost, .timedOut])
    func ordinaryNetworkFailureKeepsPartialWithoutRetry(code: URLError.Code) async throws {
        let fixture = try Fixture(statusCode: 206, existingChunks: 1, failureAfterFirstChunk: URLError(code))
        defer { fixture.cleanUp() }
        let transfer = fixture.start()
        defer { transfer.task.cancel() }
        var iterator = transfer.events.makeAsyncIterator()
        while let fraction = await iterator.next(), fraction < 0.5 {}
        // 等第一块真正落盘后再注入断网，避免错误先于数据回调到达。
        fixture.response.remainder.continuation.finish()

        do {
            _ = try await transfer.task.value
            Issue.record("Interrupted download unexpectedly succeeded")
        } catch let error as URLError {
            #expect(error.code == code)
        }
        #expect(fixture.requests.count == 1)
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize * 2))
    }

    @Test(arguments: [404, 503])
    func ordinaryHTTPFailureKeepsPartialWithoutRetry(statusCode: Int) async throws {
        let fixture = try Fixture(statusCode: statusCode, existingChunks: 1)
        defer { fixture.cleanUp() }
        fixture.response.remainder.continuation.finish()
        let transfer = fixture.start()

        do {
            _ = try await transfer.task.value
            Issue.record("Failed HTTP response unexpectedly succeeded")
        } catch let ChineseCalendarFullSeedStoreInstallError.downloadFailed(actual) {
            #expect(actual == statusCode)
        }
        #expect(fixture.requests.count == 1)
        #expect(try Data(contentsOf: fixture.partialURL) == Self.body.prefix(Self.chunkSize))
    }
}

/// FileManager 自身的线程安全由 Foundation 保证，新增可变状态仅通过 Mutex 访问。
private final class RemovalFailingFileManager: FileManager, @unchecked Sendable {
    let removalAttempts = Mutex(0)

    override func removeItem(at _: URL) throws {
        removalAttempts.withLock { $0 += 1 }
        throw CocoaError(.fileWriteNoPermission)
    }
}
