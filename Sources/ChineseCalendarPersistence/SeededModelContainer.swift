import ChineseCalendarLogging
import Foundation
import SwiftData

public enum ChineseCalendarSeedStore {
    public static let storeFileName = "ChineseCalendar.sqlite"
    public static let manifestFileName = "manifest.json"

    static let resourceBundleName = "ChineseCalendarSeedStore"
    static let resourceBundleExtension = "bundle"
    static let sharedStoreDirectoryName = "ChineseCalendarStore"
    static let downloadsDirectoryName = "ChineseCalendarDownloads"
}

public enum ChineseCalendarSeedStoreContentLevel: String, Codable, Sendable {
    case base
    case full
}

public enum ChineseCalendarStoreError: Error, LocalizedError {
    case missingAppGroupContainer(String)
    case missingSeedResource(String)
    case missingSeedStore(URL)

    public var errorDescription: String? {
        switch self {
        case let .missingAppGroupContainer(identifier):
            "Unable to open the app group container for \(identifier). Check the App Groups entitlement."
        case let .missingSeedResource(resourceName):
            "Unable to find the bundled seed store resource named \(resourceName)."
        case let .missingSeedStore(directory):
            "Unable to find \(ChineseCalendarSeedStore.storeFileName) in \(directory.path)."
        }
    }
}

public enum ChineseCalendarModelContainerFactory {
    public static let sharedContainer: ModelContainer = {
        do {
            return try makeSharedContainer()
        } catch {
            fatalError("Failed to create Chinese calendar model container: \(error.localizedDescription)")
        }
    }()

    private static var schema: Schema {
        Schema(ChineseCalendarModelSchema.models, version: ChineseCalendarModelSchema.version)
    }

    public static func makeSharedContainer(
        bundle: Bundle = .main,
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        allowsSave: Bool = false,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        ChineseCalendarLog.persistence.info("Opening shared SwiftData container")

        let storeDirectory = try sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        let lease = try ChineseCalendarStoreGenerations.acquireCurrent(in: storeDirectory, fileManager: fileManager)
        defer { withExtendedLifetime(lease) {} }
        return try installSeedStoreIfNeeded(
            from: bundle,
            to: storeDirectory,
            activeDirectory: lease.directory,
            allowsSave: allowsSave,
            fileManager: fileManager
        )
    }

    public static func makeContainer(
        at storeURL: URL,
        allowsSave: Bool = true
    ) throws -> ModelContainer {
        ChineseCalendarLog.persistence.info(
            "Creating model container at \(storeURL.path, privacy: .private), allowsSave: \(allowsSave)"
        )

        let configuration = ModelConfiguration(
            "ChineseCalendar",
            schema: schema,
            url: storeURL,
            allowsSave: allowsSave
        )

        return try ChineseCalendarStoreGenerations.openContainer(at: storeURL) {
            try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    public static func sharedStoreDirectory(
        appGroupIdentifier: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            ChineseCalendarLog.persistence.error(
                "Missing app group container for \(appGroupIdentifier, privacy: .public)"
            )
            throw ChineseCalendarStoreError.missingAppGroupContainer(appGroupIdentifier)
        }

        let directoryURL = containerURL.appendingPathComponent(
            ChineseCalendarSeedStore.sharedStoreDirectoryName,
            isDirectory: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    public static func sharedStoreURL(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> URL {
        try activeStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        .appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
    }

    public static func sharedStoreManifestURL(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> URL {
        try activeStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        .appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
    }

    private static func activeStoreDirectory(
        appGroupIdentifier: String,
        fileManager: FileManager
    ) throws -> URL {
        let root = try sharedStoreDirectory(appGroupIdentifier: appGroupIdentifier, fileManager: fileManager)
        return try ChineseCalendarStoreGenerations.activeDirectory(in: root, fileManager: fileManager)
    }

    public static func downloadsDirectory(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            ChineseCalendarLog.persistence.error(
                "Missing app group container for \(appGroupIdentifier, privacy: .public)"
            )
            throw ChineseCalendarStoreError.missingAppGroupContainer(appGroupIdentifier)
        }

        let directoryURL = containerURL.appendingPathComponent(
            ChineseCalendarSeedStore.downloadsDirectoryName,
            isDirectory: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    public static func installedStoreContentLevel(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> ChineseCalendarSeedStoreContentLevel? {
        let manifestURL = try sharedStoreManifestURL(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return nil
        }

        return try seedStoreContentLevel(at: manifestURL)
    }

    public static func installedStoreIdentityToken(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> String? {
        let manifestURL = try sharedStoreManifestURL(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return nil
        }

        return try seedStoreIdentityToken(at: manifestURL)
    }

    /// 从容器实际打开的同一代目录读取元数据，不重新解析可能已经切换的当前指针。
    public static func storeContentLevel(at storeURL: URL) throws -> ChineseCalendarSeedStoreContentLevel? {
        let manifest = storeURL.deletingLastPathComponent()
            .appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        guard FileManager.default.fileExists(atPath: manifest.path) else { return nil }
        return try seedStoreContentLevel(at: manifest)
    }

    public static func storeIdentityToken(at storeURL: URL) throws -> String? {
        let manifest = storeURL.deletingLastPathComponent()
            .appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        guard FileManager.default.fileExists(atPath: manifest.path) else { return nil }
        return try seedStoreIdentityToken(at: manifest)
    }

    private static func installSeedStoreIfNeeded(
        from bundle: Bundle = .main,
        to storeDirectory: URL,
        activeDirectory: URL,
        allowsSave: Bool,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        let storeURL = activeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
        let seedDirectory = seedStoreResourceURL(in: bundle)

        guard let seedDirectory else {
            if fileManager.fileExists(atPath: storeURL.path) {
                ChineseCalendarLog.persistence.info("Using existing installed seed store")
                return try makeContainer(at: storeURL, allowsSave: allowsSave)
            }

            ChineseCalendarLog.persistence.error("Missing bundled seed store resource")
            throw ChineseCalendarStoreError.missingSeedResource(
                "\(ChineseCalendarSeedStore.resourceBundleName).\(ChineseCalendarSeedStore.resourceBundleExtension)"
            )
        }

        if try shouldInstallSeedStore(
            seedDirectory: seedDirectory,
            storeDirectory: activeDirectory,
            fileManager: fileManager
        ) {
            ChineseCalendarLog.persistence.notice("Installing bundled seed store")

            return try installBundledGeneration(
                from: seedDirectory, in: storeDirectory, allowsSave: allowsSave, fileManager: fileManager
            )
        } else {
            ChineseCalendarLog.persistence.info("Bundled seed store is already installed")
        }

        try? ChineseCalendarStoreGenerations.collectRetired(in: storeDirectory, fileManager: fileManager)
        return try makeContainer(at: storeURL, allowsSave: allowsSave)
    }

    static func shouldInstallSeedStore(
        seedDirectory: URL,
        storeDirectory: URL,
        fileManager: FileManager
    ) throws -> Bool {
        let storeURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return true
        }

        let seedManifestURL = seedDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        guard fileManager.fileExists(atPath: seedManifestURL.path) else {
            return false
        }

        let installedManifestURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        guard fileManager.fileExists(atPath: installedManifestURL.path) else {
            return true
        }

        guard try seedStoreSchemaVersion(at: installedManifestURL)
            == ChineseCalendarModelSchema.versionIdentifier
        else {
            ChineseCalendarLog.persistence.notice("Replacing installed seed store with incompatible or missing schema")
            return true
        }

        let seedContentLevel = try seedStoreContentLevel(at: seedManifestURL)
        let installedContentLevel = try seedStoreContentLevel(at: installedManifestURL)
        if seedContentLevel == .base, installedContentLevel == .full {
            ChineseCalendarLog.persistence
                .info("Keeping installed full seed store instead of reinstalling bundled base store")
            return false
        }

        guard let seedArtifactVersion = try seedStoreArtifactVersion(at: seedManifestURL) else {
            ChineseCalendarLog.persistence.error(
                "Bundled seed store manifest has no artifactVersion; keeping the installed store"
            )
            return false
        }

        return try seedStoreArtifactVersion(at: installedManifestURL) != seedArtifactVersion
    }

    static func seedStoreIdentityToken(at manifestURL: URL) throws -> String? {
        let manifest = try seedStoreManifest(at: manifestURL)
        return manifest["artifactVersion"] as? String ?? manifest["datasetVersion"] as? String
    }
}

extension ChineseCalendarModelContainerFactory {
    private static func seedStoreArtifactVersion(at manifestURL: URL) throws -> String? {
        try seedStoreManifest(at: manifestURL)["artifactVersion"] as? String
    }

    private static func seedStoreManifest(at manifestURL: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: manifestURL)
        guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return manifest
    }

    private static func seedStoreContentLevel(at manifestURL: URL) throws -> ChineseCalendarSeedStoreContentLevel? {
        let data = try Data(contentsOf: manifestURL)
        guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawValue = manifest["seedStoreContentLevel"] as? String
        else {
            return nil
        }

        return ChineseCalendarSeedStoreContentLevel(rawValue: rawValue)
    }

    private static func seedStoreSchemaVersion(at manifestURL: URL) throws -> String? {
        let data = try Data(contentsOf: manifestURL)
        guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return manifest["schemaVersion"] as? String
    }

    private static func seedStoreResourceURL(in bundle: Bundle) -> URL? {
        bundle.url(
            forResource: ChineseCalendarSeedStore.resourceBundleName,
            withExtension: ChineseCalendarSeedStore.resourceBundleExtension
        ) ?? bundle.url(
            forResource: ChineseCalendarSeedStore.resourceBundleName,
            withExtension: nil
        )
    }

    static func copyManifestIfPresent(
        from seedDirectory: URL,
        to storeDirectory: URL,
        fileManager: FileManager
    ) throws {
        let sourceURL = seedDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return
        }

        let destinationURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

public extension ChineseCalendarModelContainerFactory {
    @discardableResult
    static func clearDownloadedSeedStore(
        bundle: Bundle = .main,
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        let storeDirectory = try sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )

        guard let seedDirectory = seedStoreResourceURL(in: bundle) else {
            ChineseCalendarLog.persistence.error("Missing bundled seed store resource")
            throw ChineseCalendarStoreError.missingSeedResource(
                "\(ChineseCalendarSeedStore.resourceBundleName).\(ChineseCalendarSeedStore.resourceBundleExtension)"
            )
        }

        ChineseCalendarLog.persistence.notice("Clearing downloaded seed store and restoring bundled base store")

        let container = try installBundledGeneration(
            from: seedDirectory, in: storeDirectory, fileManager: fileManager
        )

        do {
            let downloadsDirectory = try downloadsDirectory(
                appGroupIdentifier: appGroupIdentifier,
                fileManager: fileManager
            )
            if fileManager.fileExists(atPath: downloadsDirectory.path) {
                try fileManager.removeItem(at: downloadsDirectory)
            }
        } catch {
            // 基础库已经提交；暂存回收失败不能让界面继续使用旧库并把本次切换报告为失败。
            ChineseCalendarLog.persistence
                .error("Failed to remove download staging files: \(error.localizedDescription)")
        }

        return container
    }
}

enum ChineseCalendarSeedStoreFiles {
    static func removeStoreFiles(
        in directoryURL: URL,
        storeFileName: String = ChineseCalendarSeedStore.storeFileName,
        fileManager: FileManager = .default
    ) throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        for fileURL in try storeFileURLs(in: directoryURL, storeFileName: storeFileName, fileManager: fileManager) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    static func copyStoreFiles(
        from sourceDirectoryURL: URL,
        to destinationDirectoryURL: URL,
        storeFileName: String = ChineseCalendarSeedStore.storeFileName,
        fileManager: FileManager = .default
    ) throws {
        try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

        let sourceStoreURL = sourceDirectoryURL.appendingPathComponent(storeFileName)
        guard fileManager.fileExists(atPath: sourceStoreURL.path) else {
            ChineseCalendarLog.persistence.error(
                "Missing seed store file in \(sourceDirectoryURL.path, privacy: .private)"
            )
            throw ChineseCalendarStoreError.missingSeedStore(sourceDirectoryURL)
        }

        let destinationURL = destinationDirectoryURL.appendingPathComponent(storeFileName)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceStoreURL, to: destinationURL)
    }

    private static func storeFileURLs(
        in directoryURL: URL,
        storeFileName: String = ChineseCalendarSeedStore.storeFileName,
        fileManager: FileManager = .default
    ) throws -> [URL] {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        return try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        .filter { fileURL in
            let fileName = fileURL.lastPathComponent
            return fileName == storeFileName || fileName.hasPrefix("\(storeFileName)-")
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
