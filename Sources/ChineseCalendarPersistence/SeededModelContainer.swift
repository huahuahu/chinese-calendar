import Foundation
import SwiftData

public enum ChineseCalendarSeedStore {
    public static let storeFileName = "ChineseCalendar.sqlite"
    public static let manifestFileName = "manifest.json"

    static let resourceBundleName = "ChineseCalendarSeedStore"
    static let resourceBundleExtension = "bundle"
    static let sharedStoreDirectoryName = "ChineseCalendarStore"
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
        let configuration = ModelConfiguration(
            "ChineseCalendar",
            schema: schema,
            url: storeURL,
            allowsSave: allowsSave
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func sharedStoreDirectory(
        appGroupIdentifier: String,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw ChineseCalendarStoreError.missingAppGroupContainer(appGroupIdentifier)
        }

        let directoryURL = containerURL.appendingPathComponent(
            ChineseCalendarSeedStore.sharedStoreDirectoryName,
            isDirectory: true
        )
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
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
                return storeURL
            }

            throw ChineseCalendarStoreError.missingSeedResource(
                "\(ChineseCalendarSeedStore.resourceBundleName).\(ChineseCalendarSeedStore.resourceBundleExtension)"
            )
        }

        if try shouldInstallSeedStore(
            seedDirectory: seedDirectory,
            storeDirectory: storeDirectory,
            fileManager: fileManager
        ) {
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

        return try Data(contentsOf: seedManifestURL) != Data(contentsOf: installedManifestURL)
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

private enum ChineseCalendarSeedStoreFiles {
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
