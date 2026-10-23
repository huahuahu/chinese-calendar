import ChineseCalendarLogging
import Foundation
import SwiftData

extension ChineseCalendarModelContainerFactory {
    /// 只回收已退役且没有登记容器仍在读取的库；视图释放容器后和下次启动均可重试。
    public static func collectRetiredSeedStores(for storeURL: URL) {
        guard let root = ChineseCalendarStoreGenerations.rootDirectory(for: storeURL) else { return }
        do {
            try ChineseCalendarStoreGenerations.collectRetired(in: root)
        } catch {
            ChineseCalendarLog.persistence.error("Failed to reclaim retired seed store: \(error.localizedDescription)")
        }
    }

    static func installBundledGeneration(
        from seedDirectory: URL,
        in root: URL,
        allowsSave: Bool = false,
        fileManager: FileManager
    ) throws -> ModelContainer {
        let directory = try ChineseCalendarStoreGenerations.prepare(in: root, fileManager: fileManager)
        do {
            try ChineseCalendarSeedStoreFiles.copyStoreFiles(
                from: seedDirectory,
                to: directory,
                fileManager: fileManager
            )
            try copyManifestIfPresent(from: seedDirectory, to: directory, fileManager: fileManager)
            let storeURL = directory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
            _ = try storeContentLevel(at: storeURL)
            _ = try storeIdentityToken(at: storeURL)
            // 候选库必须能打开，发布失败不会影响仍在使用的旧目录。
            let container = try makeContainer(at: storeURL, allowsSave: allowsSave)
            try ChineseCalendarStoreGenerations.activate(directory, in: root, fileManager: fileManager)
            try? ChineseCalendarStoreGenerations.collectRetired(in: root, fileManager: fileManager)
            return container
        } catch {
            ChineseCalendarStoreGenerations.abandon(directory, in: root, fileManager: fileManager)
            throw error
        }
    }
}
