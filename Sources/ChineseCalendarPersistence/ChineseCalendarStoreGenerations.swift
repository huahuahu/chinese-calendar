import Foundation
import SwiftData
import Synchronization

/// 每次换库使用独立目录，当前版本只通过原子指针发布；在用数据库从不原地删除。
enum ChineseCalendarStoreGenerations {
    private static let generationsName = "generations"
    private static let currentName = "current-generation"
    private static let access = Mutex(Access())

    private struct WeakContainer {
        weak var value: ModelContainer?
    }

    private struct Access {
        var containers: [URL: [WeakContainer]] = [:]
        var pending: Set<URL> = []
        var readLeases: [URL: Int] = [:]
    }

    final class ReadLease: Sendable {
        let directory: URL

        init(directory: URL) {
            self.directory = directory
        }

        deinit {
            ChineseCalendarStoreGenerations.access.withLock { state in
                state.readLeases[directory.standardizedFileURL, default: 0] -= 1
            }
        }
    }

    /// 当前指针解析与读 lease 登记处于同一事务，覆盖随后真正打开容器前的窗口。
    static func acquireCurrent(in root: URL, fileManager: FileManager = .default) throws -> ReadLease {
        try access.withLock { state in
            let directory = try activeDirectory(in: root, fileManager: fileManager)
            state.readLeases[directory.standardizedFileURL, default: 0] += 1
            return ReadLease(directory: directory)
        }
    }

    static func activeDirectory(in root: URL, fileManager: FileManager = .default) throws -> URL {
        let pointer = root.appendingPathComponent(currentName)
        guard fileManager.fileExists(atPath: pointer.path) else { return root }
        let name = try String(contentsOf: pointer, encoding: .utf8)
        guard UUID(uuidString: name) != nil else { throw CocoaError(.fileReadCorruptFile) }
        return root.appendingPathComponent(generationsName, isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
    }

    static func prepare(in root: URL, fileManager: FileManager = .default) throws -> URL {
        try access.withLock { state in
            let directory = root.appendingPathComponent(generationsName, isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            state.pending.insert(directory.standardizedFileURL)
            return directory
        }
    }

    static func activate(_ directory: URL, in root: URL, fileManager: FileManager = .default) throws {
        try access.withLock { state in
            try Task.checkCancellation()
            let storeURL = directory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
            guard fileManager.fileExists(atPath: storeURL.path) else {
                throw ChineseCalendarStoreError.missingSeedStore(directory)
            }
            try Data(directory.lastPathComponent.utf8)
                .write(to: root.appendingPathComponent(currentName), options: .atomic)
            state.pending.remove(directory.standardizedFileURL)
        }
    }

    static func abandon(_ directory: URL, in root: URL, fileManager: FileManager = .default) {
        access.withLock { state in _ = state.pending.remove(directory.standardizedFileURL) }
        try? collectRetired(in: root, fileManager: fileManager)
    }

    /// 登记与回收共用锁，避免容器打开过程中目录被回收。
    static func openContainer(at storeURL: URL, create: () throws -> ModelContainer) throws -> ModelContainer {
        try access.withLock { state in
            let container = try create()
            let key = storeURL.standardizedFileURL
            state.containers[key, default: []].removeAll { $0.value == nil }
            state.containers[key, default: []].append(WeakContainer(value: container))
            return container
        }
    }

    /// 当前 App 的所有共享库读取均通过 factory 登记；未来独立进程读库需要跨进程 lease。
    static func collectRetired(in root: URL, fileManager: FileManager = .default) throws {
        try access.withLock { state in
            let active = try activeDirectory(in: root, fileManager: fileManager).standardizedFileURL
            let generations = root.appendingPathComponent(generationsName, isDirectory: true)
            let directories = fileManager.fileExists(atPath: generations.path)
                ? try fileManager.contentsOfDirectory(at: generations, includingPropertiesForKeys: nil) : []
            for directory in directories where UUID(uuidString: directory.lastPathComponent) != nil {
                let key = directory.standardizedFileURL
                guard key != active, !state.pending.contains(key), !hasReaders(in: key, state: &state) else {
                    continue
                }
                try fileManager.removeItem(at: directory)
            }
            // 兼容旧版固定路径；首次发布 generation 后也须等旧容器释放再回收。
            if active != root.standardizedFileURL, !hasReaders(in: root, state: &state) {
                try ChineseCalendarSeedStoreFiles.removeStoreFiles(in: root, fileManager: fileManager)
                let manifest = root.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName)
                if fileManager.fileExists(atPath: manifest.path) { try fileManager.removeItem(at: manifest) }
            }
        }
    }

    static func rootDirectory(for storeURL: URL) -> URL? {
        let directory = storeURL.deletingLastPathComponent()
        if directory.deletingLastPathComponent().lastPathComponent == generationsName {
            return directory.deletingLastPathComponent().deletingLastPathComponent()
        }
        return directory.lastPathComponent == ChineseCalendarSeedStore.sharedStoreDirectoryName ? directory : nil
    }

    private static func hasReaders(in directory: URL, state: inout Access) -> Bool {
        if state.readLeases[directory.standardizedFileURL, default: 0] > 0 { return true }
        let key = directory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName).standardizedFileURL
        state.containers[key]?.removeAll { $0.value == nil }
        return !(state.containers[key]?.isEmpty ?? true)
    }
}
