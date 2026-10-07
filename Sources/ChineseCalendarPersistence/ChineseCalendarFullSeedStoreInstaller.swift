import ChineseCalendarLogging
import CryptoKit
import Foundation
import SwiftData

public struct FullSeedStoreManifest: Decodable, Sendable {
    public let datasetVersion: String
    public let artifactVersion: String?
    public let schemaVersion: String
    public let seedStoreContentLevel: ChineseCalendarSeedStoreContentLevel
    public let seedStoreFormatVersion: Int
    public let storeFileName: String
    public let byteCount: Int64
    public let sha256: String
    public let downloadURL: URL

    /// 构造远端清单，文件大小和摘要用于下载进度及完整性校验。
    public init(
        datasetVersion: String,
        artifactVersion: String? = nil,
        schemaVersion: String,
        seedStoreContentLevel: ChineseCalendarSeedStoreContentLevel,
        seedStoreFormatVersion: Int,
        storeFileName: String = ChineseCalendarSeedStore.storeFileName,
        byteCount: Int64,
        sha256: String,
        downloadURL: URL
    ) {
        self.datasetVersion = datasetVersion
        self.artifactVersion = artifactVersion
        self.schemaVersion = schemaVersion
        self.seedStoreContentLevel = seedStoreContentLevel
        self.seedStoreFormatVersion = seedStoreFormatVersion
        self.storeFileName = storeFileName
        self.byteCount = byteCount
        self.sha256 = sha256
        self.downloadURL = downloadURL
    }
}

public struct FullSeedStoreInstallResult: Sendable {
    public let manifest: FullSeedStoreManifest
    public let storeURL: URL
}

public enum ChineseCalendarFullSeedStoreInstallEvent: Sendable {
    case downloading(progress: Double)
    case validating
    case installing
    case installed(FullSeedStoreInstallResult)
}

public enum ChineseCalendarFullSeedStoreInstallError: Error, LocalizedError {
    case unsupportedContentLevel(ChineseCalendarSeedStoreContentLevel)
    case unsupportedStoreFileName(String)
    case unsupportedSchemaVersion(String, expected: String)
    case invalidManifestByteCount(Int64)
    case invalidManifestChecksum(String)
    case invalidContentRange
    case downloadFailed(Int)
    case rangeNotSatisfiable
    case invalidByteCount(expected: Int64, actual: Int64)
    case checksumMismatch(expected: String, actual: String)
    case missingDownloadedStore(URL)

    /// 提供供日志与工具使用的诊断信息；用户提示由界面层按错误类型映射。
    public var errorDescription: String? {
        switch self {
        case let .unsupportedContentLevel(contentLevel):
            "Remote seed store content level must be full, got \(contentLevel.rawValue)."
        case let .unsupportedStoreFileName(fileName):
            "Remote seed store file name must be \(ChineseCalendarSeedStore.storeFileName), got \(fileName)."
        case let .unsupportedSchemaVersion(version, expected):
            "Remote seed store schema version \(version) is not supported by this app. Expected \(expected)."
        case let .invalidManifestByteCount(byteCount):
            "Remote seed store manifest must specify a positive file size, got \(byteCount)."
        case let .invalidManifestChecksum(checksum):
            "Remote seed store manifest must specify a SHA-256 checksum, got \(checksum)."
        case .invalidContentRange:
            "Remote seed store response does not match the requested byte range."
        case let .downloadFailed(statusCode):
            "Remote seed store download failed with HTTP status \(statusCode)."
        case .rangeNotSatisfiable:
            "Remote seed store partial download is no longer valid."
        case let .invalidByteCount(expected, actual):
            "Remote seed store size mismatch. Expected \(expected) bytes, got \(actual)."
        case let .checksumMismatch(expected, actual):
            "Remote seed store checksum mismatch. Expected \(expected), got \(actual)."
        case let .missingDownloadedStore(directory):
            "Remote seed store download did not contain \(ChineseCalendarSeedStore.storeFileName) in \(directory.path)."
        }
    }
}

public actor ChineseCalendarFullSeedStoreInstaller {
    private static let supportedSchemaVersion = ChineseCalendarModelSchema.versionIdentifier

    private let configuration: FullSeedStoreConfig
    private let appGroupIdentifier: String
    private let session: URLSession
    private let fileManager: FileManager
    private let decoder = JSONDecoder()

    /// 注入下载配置和存储依赖，测试时可替换网络会话及文件管理器。
    public init(
        configuration: FullSeedStoreConfig,
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.appGroupIdentifier = appGroupIdentifier
        self.session = session
        self.fileManager = fileManager
    }

    /// 启动一次安装，通过事件流返回阶段进度和最终结果。
    public func installEvents() -> AsyncThrowingStream<ChineseCalendarFullSeedStoreInstallEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try await install { event in
                        continuation.yield(event)
                    }
                    continuation.yield(.installed(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // 内部 Task 不会随消费任务自动取消，在事件流终止时主动传递取消。
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// 按下载、校验、替换存储的顺序执行完整安装。
    private func install(
        eventHandler: @escaping @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) async throws -> FullSeedStoreInstallResult {
        let manifest = try await fetchRemoteManifest()
        try Self.validate(manifest)

        let downloadsDirectory = try ChineseCalendarModelContainerFactory.downloadsDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        let stagingDirectory = downloadsDirectory.appendingPathComponent("FullSeedStoreStaging", isDirectory: true)
        let partialDirectory = Self.partialStoreDirectory(in: downloadsDirectory, manifest: manifest)
        let downloadedStoreURL = stagingDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
        let partialStoreURL = partialDirectory
            .appendingPathComponent("\(ChineseCalendarSeedStore.storeFileName).partial")

        // 每次清空暂存区，续传片段则保留在按清单隔离的目录中。
        try resetDirectory(stagingDirectory)
        try excludeFromBackup(downloadsDirectory)
        try excludeFromBackup(stagingDirectory)
        try fileManager.createDirectory(at: partialDirectory, withIntermediateDirectories: true)
        try excludeFromBackup(partialDirectory)
        let temporaryDownloadURL = try await downloadStore(
            manifest: manifest,
            partialURL: partialStoreURL,
            destinationURL: downloadedStoreURL,
            eventHandler: eventHandler
        )

        // 文件完整性和数据库关系均通过校验后，才替换当前存储。
        eventHandler(.validating)
        ChineseCalendarLog.persistence.info("Validating downloaded full seed store")
        try validateDownloadedStore(at: temporaryDownloadURL, manifest: manifest)
        try validateStoreCanOpen(at: temporaryDownloadURL)

        eventHandler(.installing)
        ChineseCalendarLog.persistence.info("Full seed store validation passed; installing")
        let storeDirectory = try ChineseCalendarModelContainerFactory.sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        let storeURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)

        // 移除旧存储文件，再放入已验证的新数据库并记录安装信息。
        try ChineseCalendarSeedStoreFiles.removeStoreFiles(
            in: storeDirectory,
            fileManager: fileManager
        )
        try fileManager.moveItem(at: temporaryDownloadURL, to: storeURL)
        try writeInstalledManifest(manifest, to: storeDirectory)
        try excludeFromBackup(storeDirectory)
        try? fileManager.removeItem(at: stagingDirectory)
        try? fileManager.removeItem(at: partialDirectory)

        ChineseCalendarLog.persistence.notice("Installed full SwiftData seed store")
        return FullSeedStoreInstallResult(manifest: manifest, storeURL: storeURL)
    }

    /// 获取下载清单，读取文件地址、总大小和校验信息。
    private func fetchRemoteManifest() async throws -> FullSeedStoreManifest {
        let (data, response) = try await session.data(from: configuration.manifestURL)
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if let statusCode, !(200 ... 299).contains(statusCode) {
            throw ChineseCalendarFullSeedStoreInstallError.downloadFailed(statusCode)
        }

        return try decoder.decode(FullSeedStoreManifest.self, from: data)
    }

    /// 下载前检查清单大小、摘要、内容类型、文件名和数据库版本。
    static func validate(_ manifest: FullSeedStoreManifest) throws {
        guard manifest.byteCount > 0 else {
            throw ChineseCalendarFullSeedStoreInstallError.invalidManifestByteCount(manifest.byteCount)
        }
        guard manifest.seedStoreContentLevel == .full else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedContentLevel(manifest.seedStoreContentLevel)
        }
        guard manifest.storeFileName == ChineseCalendarSeedStore.storeFileName else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedStoreFileName(manifest.storeFileName)
        }
        guard manifest.schemaVersion == supportedSchemaVersion else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedSchemaVersion(
                manifest.schemaVersion,
                expected: supportedSchemaVersion
            )
        }
        guard manifest.sha256.utf8.count == 64,
              manifest.sha256.utf8.allSatisfy({ (48 ... 57).contains($0) || (65 ... 70).contains($0) ||
                      (97 ... 102).contains($0) })
        else {
            throw ChineseCalendarFullSeedStoreInstallError.invalidManifestChecksum(manifest.sha256)
        }
    }

    /// 以完整 SHA-256 隔离片段；同一内容可续传，内容更新后自动使用新目录。
    static func partialStoreDirectory(in downloadsDirectory: URL, manifest: FullSeedStoreManifest) -> URL {
        downloadsDirectory.appendingPathComponent(
            "FullSeedStorePartial-\(manifest.sha256.lowercased())",
            isDirectory: true
        )
    }

    /// 下载到暂存位置，复用已有片段并持续上报文件传输进度。
    func downloadStore(
        manifest: FullSeedStoreManifest,
        partialURL: URL,
        destinationURL: URL,
        eventHandler: @escaping @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) async throws -> URL {
        try Self.validate(manifest)
        try Task.checkCancellation()
        let downloadedByteCount = try existingPartialByteCount(at: partialURL, manifest: manifest)
        eventHandler(.downloading(progress: Double(downloadedByteCount) / Double(manifest.byteCount)))
        // 大小已完整的片段跳过网络请求，内容正确性仍由后续校验确认。
        if downloadedByteCount < manifest.byteCount {
            do {
                try await downloadPartialStore(
                    manifest: manifest, partialURL: partialURL, offset: downloadedByteCount,
                    eventHandler: eventHandler
                )
            } catch let error as ChineseCalendarFullSeedStoreInstallError {
                guard downloadedByteCount > 0 else { throw error }
                switch error {
                case .rangeNotSatisfiable, .invalidContentRange: break
                default: throw error
                }
                try Task.checkCancellation()
                // 请求已结束且文件已关闭；删除失败直接抛出，不能带着旧片段重试。
                try fileManager.removeItem(at: partialURL)
                ChineseCalendarLog.persistence.notice("Invalid full seed store resume; retrying once from byte 0")
                eventHandler(.downloading(progress: 0))
                // 重试位于 catch 内，失败直接向上传递，不会再次进入回退。
                try await downloadPartialStore(
                    manifest: manifest, partialURL: partialURL, offset: 0, eventHandler: eventHandler
                )
            }
        } else {
            ChineseCalendarLog.persistence
                .info("Reusing complete full seed store partial: \(downloadedByteCount) bytes")
        }
        try Task.checkCancellation()

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: partialURL, to: destinationURL)
        return destinationURL
    }
}

private extension ChineseCalendarFullSeedStoreInstaller {
    /// 只执行一次网络请求；范围无效时由调用方决定是否清理并重试。
    func downloadPartialStore(
        manifest: FullSeedStoreManifest,
        partialURL: URL,
        offset: Int64,
        eventHandler: @escaping @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) async throws {
        try Task.checkCancellation()
        ChineseCalendarLog.persistence.info(
            "Starting full seed store download: offset=\(offset), total=\(manifest.byteCount)"
        )
        var request = URLRequest(url: manifest.downloadURL)
        // 字节偏移对应原始文件，避免传输压缩改变 Range 的含义。
        request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        if offset > 0 {
            request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
        }
        let downloader = FullSeedStoreDownloader(
            partialURL: partialURL,
            expectedByteCount: manifest.byteCount,
            requestedOffset: offset
        ) { fraction in
            eventHandler(.downloading(progress: fraction))
        }
        // 接收的数据直接写入持久片段；失败或取消时保留已经写入的部分。
        try await downloader.download(for: request, using: session)
    }

    /// 读取可续传的片段大小；文件缺失或大小异常时清理并从零开始。
    private func existingPartialByteCount(
        at partialURL: URL,
        manifest: FullSeedStoreManifest
    ) throws -> Int64 {
        guard fileManager.fileExists(atPath: partialURL.path) else { return 0 }
        let attributes = try fileManager.attributesOfItem(atPath: partialURL.path)
        guard let byteCount = attributes[.size] as? Int64,
              byteCount > 0,
              byteCount <= manifest.byteCount
        else {
            try fileManager.removeItem(at: partialURL)
            return 0
        }

        return byteCount
    }

    /// 依次核对文件存在、字节数和 SHA-256，确认下载内容完整。
    private func validateDownloadedStore(
        at storeURL: URL,
        manifest: FullSeedStoreManifest
    ) throws {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            throw ChineseCalendarFullSeedStoreInstallError.missingDownloadedStore(storeURL.deletingLastPathComponent())
        }

        let attributes = try fileManager.attributesOfItem(atPath: storeURL.path)
        let byteCount = attributes[.size] as? Int64 ?? 0
        guard byteCount == manifest.byteCount else {
            throw ChineseCalendarFullSeedStoreInstallError.invalidByteCount(
                expected: manifest.byteCount,
                actual: byteCount
            )
        }

        // 先检查大小，再计算开销较大的文件摘要。
        let checksum = try sha256(for: storeURL)
        guard checksum.caseInsensitiveCompare(manifest.sha256) == .orderedSame else {
            throw ChineseCalendarFullSeedStoreInstallError.checksumMismatch(
                expected: manifest.sha256,
                actual: checksum
            )
        }
    }

    /// 以禁止保存的配置打开下载数据库，并检查关键模型关系。
    private func validateStoreCanOpen(at storeURL: URL) throws {
        let container = try ChineseCalendarModelContainerFactory.makeContainer(at: storeURL, allowsSave: false)
        try ChineseCalendarRelationshipValidation.validate(in: ModelContext(container))
    }

    /// 记录已安装的版本和文件信息，供后续识别本地数据。
    private func writeInstalledManifest(
        _ manifest: FullSeedStoreManifest,
        to storeDirectory: URL
    ) throws {
        let manifestURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        var data: [String: Any] = [
            "datasetVersion": manifest.datasetVersion,
            "schemaVersion": manifest.schemaVersion,
            "seedStoreContentLevel": manifest.seedStoreContentLevel.rawValue,
            "seedStoreFormatVersion": manifest.seedStoreFormatVersion,
            "storeFileName": manifest.storeFileName,
            "byteCount": manifest.byteCount,
            "sha256": manifest.sha256,
            "downloadURL": manifest.downloadURL.absoluteString,
            "installedAt": ISO8601DateFormatter().string(from: Date())
        ]
        if let artifactVersion = manifest.artifactVersion {
            data["artifactVersion"] = artifactVersion
        }
        var encodedData = try JSONSerialization.data(
            withJSONObject: data,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        encodedData.append(Data("\n".utf8))
        // 原子写入清单，避免留下只写了一部分的 JSON。
        try encodedData.write(to: manifestURL, options: .atomic)
    }

    /// 分块计算 SHA-256，返回小写十六进制摘要。
    private func sha256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? handle.close()
        }

        var hasher = SHA256()
        // 逐块释放临时数据，控制大文件校验的内存占用。
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1024 * 1024)
            guard !data.isEmpty else {
                return false
            }
            hasher.update(data: data)
            return true
        }) {}

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// 删除并重建暂存目录，避免上次安装残留影响本次流程。
    private func resetDirectory(_ directoryURL: URL) throws {
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// 下载数据可重新获取，将其排除在系统备份之外。
    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}
