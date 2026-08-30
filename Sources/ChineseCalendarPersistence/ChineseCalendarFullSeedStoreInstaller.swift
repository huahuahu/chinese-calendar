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
    case downloading(progress: Double?)
    case validating
    case installing
    case installed(FullSeedStoreInstallResult)
}

public enum ChineseCalendarFullSeedStoreInstallError: Error, LocalizedError {
    case unsupportedContentLevel(ChineseCalendarSeedStoreContentLevel)
    case unsupportedStoreFileName(String)
    case unsupportedSchemaVersion(String, expected: String)
    case downloadFailed(Int)
    case rangeNotSatisfiable
    case invalidByteCount(expected: Int64, actual: Int64)
    case checksumMismatch(expected: String, actual: String)
    case missingDownloadedStore(URL)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedContentLevel(contentLevel):
            "Remote seed store content level must be full, got \(contentLevel.rawValue)."
        case let .unsupportedStoreFileName(fileName):
            "Remote seed store file name must be \(ChineseCalendarSeedStore.storeFileName), got \(fileName)."
        case let .unsupportedSchemaVersion(version, expected):
            "Remote seed store schema version \(version) is not supported by this app. Expected \(expected)."
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

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func install() async throws -> FullSeedStoreInstallResult {
        try await install { _ in }
    }

    private func install(
        eventHandler: @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) async throws -> FullSeedStoreInstallResult {
        let manifest = try await fetchRemoteManifest()
        try validate(manifest)

        eventHandler(.downloading(progress: nil))
        let downloadsDirectory = try ChineseCalendarModelContainerFactory.downloadsDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        let stagingDirectory = downloadsDirectory.appendingPathComponent("FullSeedStoreStaging", isDirectory: true)
        let partialDirectory = partialStoreDirectory(in: downloadsDirectory, manifest: manifest)
        let downloadedStoreURL = stagingDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
        let partialStoreURL = partialDirectory
            .appendingPathComponent("\(ChineseCalendarSeedStore.storeFileName).partial")

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

        eventHandler(.validating)
        try validateDownloadedStore(at: temporaryDownloadURL, manifest: manifest)
        try validateStoreCanOpen(at: temporaryDownloadURL)

        eventHandler(.installing)
        let storeDirectory = try ChineseCalendarModelContainerFactory.sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        let storeURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)

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

    private func fetchRemoteManifest() async throws -> FullSeedStoreManifest {
        let (data, response) = try await session.data(from: configuration.manifestURL)
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if let statusCode, !(200 ... 299).contains(statusCode) {
            throw ChineseCalendarFullSeedStoreInstallError.downloadFailed(statusCode)
        }

        return try decoder.decode(FullSeedStoreManifest.self, from: data)
    }

    private func validate(_ manifest: FullSeedStoreManifest) throws {
        guard manifest.seedStoreContentLevel == .full else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedContentLevel(manifest.seedStoreContentLevel)
        }
        guard manifest.storeFileName == ChineseCalendarSeedStore.storeFileName else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedStoreFileName(manifest.storeFileName)
        }
        guard manifest.schemaVersion == Self.supportedSchemaVersion else {
            throw ChineseCalendarFullSeedStoreInstallError.unsupportedSchemaVersion(
                manifest.schemaVersion,
                expected: Self.supportedSchemaVersion
            )
        }
    }

    private func downloadStore(
        manifest: FullSeedStoreManifest,
        partialURL: URL,
        destinationURL: URL,
        eventHandler: @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) async throws -> URL {
        var downloadedByteCount = existingPartialByteCount(at: partialURL, manifest: manifest)
        if downloadedByteCount == manifest.byteCount {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: partialURL, to: destinationURL)
            eventHandler(.downloading(progress: 1))
            return destinationURL
        }

        var request = URLRequest(url: manifest.downloadURL)
        if downloadedByteCount > 0 {
            request.setValue("bytes=\(downloadedByteCount)-", forHTTPHeaderField: "Range")
        }

        let (downloadedURL, response) = try await session.download(for: request)
        let didRestart = try normalizeDownloadResponse(
            response,
            partialURL: partialURL,
            requestedOffset: downloadedByteCount
        )
        if didRestart {
            downloadedByteCount = 0
        }

        if downloadedByteCount == 0 {
            fileManager.createFile(atPath: partialURL.path, contents: nil)
        }

        downloadedByteCount = try append(
            downloadedURL,
            to: partialURL,
            downloadedByteCount: downloadedByteCount,
            expectedLength: manifest.byteCount,
            eventHandler: eventHandler
        )

        eventHandler(.downloading(progress: progress(downloadedByteCount, expectedLength: manifest.byteCount)))
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: partialURL, to: destinationURL)
        return destinationURL
    }
}

private extension ChineseCalendarFullSeedStoreInstaller {
    private func existingPartialByteCount(
        at partialURL: URL,
        manifest: FullSeedStoreManifest
    ) -> Int64 {
        guard fileManager.fileExists(atPath: partialURL.path),
              let attributes = try? fileManager.attributesOfItem(atPath: partialURL.path),
              let byteCount = attributes[.size] as? Int64,
              byteCount > 0,
              byteCount <= manifest.byteCount
        else {
            try? fileManager.removeItem(at: partialURL)
            return 0
        }

        return byteCount
    }

    private func append(
        _ downloadedURL: URL,
        to partialURL: URL,
        downloadedByteCount: Int64,
        expectedLength: Int64,
        eventHandler: @Sendable (ChineseCalendarFullSeedStoreInstallEvent) -> Void
    ) throws -> Int64 {
        let sourceHandle = try FileHandle(forReadingFrom: downloadedURL)
        defer {
            try? sourceHandle.close()
            try? fileManager.removeItem(at: downloadedURL)
        }

        let destinationHandle = try FileHandle(forWritingTo: partialURL)
        defer {
            try? destinationHandle.close()
        }

        try destinationHandle.seekToEnd()

        var downloadedByteCount = downloadedByteCount
        while true {
            try Task.checkCancellation()
            let data = sourceHandle.readData(ofLength: 1024 * 1024)
            guard !data.isEmpty else {
                break
            }

            try destinationHandle.write(contentsOf: data)
            downloadedByteCount += Int64(data.count)
            eventHandler(.downloading(progress: progress(downloadedByteCount, expectedLength: expectedLength)))
        }

        return downloadedByteCount
    }

    private func normalizeDownloadResponse(
        _ response: URLResponse,
        partialURL: URL,
        requestedOffset: Int64
    ) throws -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        switch (requestedOffset, httpResponse.statusCode) {
        case (0, 200), (0, 206):
            return false
        case (1..., 206):
            return false
        case (1..., 200):
            try? fileManager.removeItem(at: partialURL)
            fileManager.createFile(atPath: partialURL.path, contents: nil)
            return true
        case (_, 416):
            try? fileManager.removeItem(at: partialURL)
            throw ChineseCalendarFullSeedStoreInstallError.rangeNotSatisfiable
        default:
            throw ChineseCalendarFullSeedStoreInstallError.downloadFailed(httpResponse.statusCode)
        }
    }

    private func progress(_ downloadedByteCount: Int64, expectedLength: Int64) -> Double? {
        guard expectedLength > 0 else {
            return nil
        }

        return min(1, max(0, Double(downloadedByteCount) / Double(expectedLength)))
    }

    private func partialStoreDirectory(
        in downloadsDirectory: URL,
        manifest: FullSeedStoreManifest
    ) -> URL {
        downloadsDirectory.appendingPathComponent(
            "FullSeedStorePartial-\(manifest.datasetVersion)-\(manifest.sha256.prefix(12))",
            isDirectory: true
        )
    }

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

        let checksum = try sha256(for: storeURL)
        guard checksum.caseInsensitiveCompare(manifest.sha256) == .orderedSame else {
            throw ChineseCalendarFullSeedStoreInstallError.checksumMismatch(
                expected: manifest.sha256,
                actual: checksum
            )
        }
    }

    private func validateStoreCanOpen(at storeURL: URL) throws {
        _ = try ChineseCalendarModelContainerFactory.makeContainer(at: storeURL, allowsSave: false)
    }

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
        try encodedData.write(to: manifestURL, options: .atomic)
    }

    private func sha256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? handle.close()
        }

        var hasher = SHA256()
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

    private func resetDirectory(_ directoryURL: URL) throws {
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}
