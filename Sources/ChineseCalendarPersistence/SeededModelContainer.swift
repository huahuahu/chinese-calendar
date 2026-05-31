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

enum ChineseCalendarStoreError: Error, LocalizedError {
    case missingAppGroupContainer(String)
    case missingSeedResource(String)
    case missingSeedStore(URL)

    var errorDescription: String? {
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
        let storeURL = try installSeedStoreIfNeeded(
            from: bundle,
            to: storeDirectory,
            fileManager: fileManager
        )

        return try makeContainer(at: storeURL, allowsSave: allowsSave)
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

        return try ModelContainer(for: schema, configurations: [configuration])
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
        try sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        .appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
    }

    public static func sharedStoreManifestURL(
        appGroupIdentifier: String = ChineseCalendarAppConfiguration.appGroupIdentifier,
        fileManager: FileManager = .default
    ) throws -> URL {
        try sharedStoreDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        .appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
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

        let data = try Data(contentsOf: manifestURL)
        guard let manifest = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return manifest["datasetVersion"] as? String ?? manifest["generatedAt"] as? String
    }

    private static func installSeedStoreIfNeeded(
        from bundle: Bundle = .main,
        to storeDirectory: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        let storeURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
        let seedDirectory = seedStoreResourceURL(in: bundle)

        guard let seedDirectory else {
            if fileManager.fileExists(atPath: storeURL.path) {
                ChineseCalendarLog.persistence.info("Using existing installed seed store")
                return storeURL
            }

            ChineseCalendarLog.persistence.error("Missing bundled seed store resource")
            throw ChineseCalendarStoreError.missingSeedResource(
                "\(ChineseCalendarSeedStore.resourceBundleName).\(ChineseCalendarSeedStore.resourceBundleExtension)"
            )
        }

        if try shouldInstallSeedStore(
            seedDirectory: seedDirectory,
            storeDirectory: storeDirectory,
            fileManager: fileManager
        ) {
            ChineseCalendarLog.persistence.notice("Installing bundled seed store")

            try ChineseCalendarSeedStoreFiles.removeStoreFiles(
                in: storeDirectory,
                fileManager: fileManager
            )
            try ChineseCalendarSeedStoreFiles.copyStoreFiles(
                from: seedDirectory,
                to: storeDirectory,
                fileManager: fileManager
            )
            try copyManifestIfPresent(
                from: seedDirectory,
                to: storeDirectory,
                fileManager: fileManager
            )
        } else {
            ChineseCalendarLog.persistence.info("Bundled seed store is already installed")
        }

        return storeURL
    }

    private static func shouldInstallSeedStore(
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

        let seedContentLevel = try seedStoreContentLevel(at: seedManifestURL)
        let installedContentLevel = try seedStoreContentLevel(at: installedManifestURL)
        if seedContentLevel == .base, installedContentLevel == .full {
            ChineseCalendarLog.persistence
                .info("Keeping installed full seed store instead of reinstalling bundled base store")
            return false
        }

        return try Data(contentsOf: seedManifestURL) != Data(contentsOf: installedManifestURL)
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

    private static func seedStoreResourceURL(in bundle: Bundle) -> URL? {
        bundle.url(
            forResource: ChineseCalendarSeedStore.resourceBundleName,
            withExtension: ChineseCalendarSeedStore.resourceBundleExtension
        ) ?? bundle.url(
            forResource: ChineseCalendarSeedStore.resourceBundleName,
            withExtension: nil
        )
    }

    private static func copyManifestIfPresent(
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
    ) throws -> URL {
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

        try ChineseCalendarSeedStoreFiles.removeStoreFiles(
            in: storeDirectory,
            fileManager: fileManager
        )

        let installedManifestURL = storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
        if fileManager.fileExists(atPath: installedManifestURL.path) {
            try fileManager.removeItem(at: installedManifestURL)
        }

        try ChineseCalendarSeedStoreFiles.copyStoreFiles(
            from: seedDirectory,
            to: storeDirectory,
            fileManager: fileManager
        )
        try copyManifestIfPresent(
            from: seedDirectory,
            to: storeDirectory,
            fileManager: fileManager
        )

        let downloadsDirectory = try downloadsDirectory(
            appGroupIdentifier: appGroupIdentifier,
            fileManager: fileManager
        )
        if fileManager.fileExists(atPath: downloadsDirectory.path) {
            try fileManager.removeItem(at: downloadsDirectory)
        }

        return storeDirectory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
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
