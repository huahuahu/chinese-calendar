@testable import ChineseCalendarPersistence
import Foundation
import SwiftData
import Testing

@Suite("文件数据库安全换代")
struct StoreGenerationTests {
    @Test(arguments: [true, false])
    func retainedMonthRemainsReadableAcrossReplacement(legacy: Bool) throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let retired = try autoreleasepool { try verifyReplacement(in: root, legacy: legacy) }
        try ChineseCalendarStoreGenerations.collectRetired(in: root)
        #expect(!FileManager.default.fileExists(atPath: retired.path))
        let current = try ChineseCalendarStoreGenerations.activeDirectory(in: root)
        #expect(FileManager.default.fileExists(atPath: storeURL(in: current).path))
    }

    @Test func pendingGenerationIsExcludedFromCollectionUntilAbandoned() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pending = try ChineseCalendarStoreGenerations.prepare(in: root)
        try ChineseCalendarStoreGenerations.collectRetired(in: root)
        #expect(FileManager.default.fileExists(atPath: pending.path))
        ChineseCalendarStoreGenerations.abandon(pending, in: root)
        #expect(!FileManager.default.fileExists(atPath: pending.path))
        #expect(try ChineseCalendarStoreGenerations.activeDirectory(in: root) == root)
    }

    @Test func resolvedDirectoryRemainsAvailableUntilItsReadLeaseEnds() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = try ChineseCalendarStoreGenerations.prepare(in: root)
        try Data().write(to: storeURL(in: first))
        try ChineseCalendarStoreGenerations.activate(first, in: root)
        var lease: ChineseCalendarStoreGenerations.ReadLease? = try ChineseCalendarStoreGenerations
            .acquireCurrent(in: root)
        #expect(lease?.directory == first)
        let second = try ChineseCalendarStoreGenerations.prepare(in: root)
        try Data().write(to: storeURL(in: second))
        try ChineseCalendarStoreGenerations.activate(second, in: root)
        try ChineseCalendarStoreGenerations.collectRetired(in: root)
        #expect(FileManager.default.fileExists(atPath: first.path))
        lease = nil
        try ChineseCalendarStoreGenerations.collectRetired(in: root)
        #expect(!FileManager.default.fileExists(atPath: first.path))
    }

    @Test func failedPreparationKeepsThePublishedStoreAndManifest() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try autoreleasepool {
            let current = try ChineseCalendarStoreGenerations.prepare(in: root)
            let container = try makeStore(in: current, year: 2026, contentLevel: .full)
            try ChineseCalendarStoreGenerations.activate(current, in: root)
            let seed = root.appendingPathComponent("invalid-seed")
            try FileManager.default.createDirectory(at: seed, withIntermediateDirectories: true)
            try Data("invalid database".utf8).write(to: storeURL(in: seed))
            try Data("invalid manifest".utf8)
                .write(to: seed.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName))
            #expect(throws: (any Error).self) {
                try ChineseCalendarModelContainerFactory.installBundledGeneration(
                    from: seed, in: root, fileManager: .default
                )
            }
            #expect(try ChineseCalendarStoreGenerations.activeDirectory(in: root) == current)
            #expect(try ChineseCalendarModelContainerFactory.storeContentLevel(at: storeURL(in: current)) == .full)
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ChineseLunarDay>()) == 1)
        }
    }

    @Test func cancelledPublisherCannotReplaceTheCurrentGeneration() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pending = try ChineseCalendarStoreGenerations.prepare(in: root)
        try Data().write(to: storeURL(in: pending))
        await #expect(throws: CancellationError.self) {
            try await Task {
                withUnsafeCurrentTask { $0?.cancel() }
                try ChineseCalendarStoreGenerations.activate(pending, in: root)
            }.value
        }
        #expect(try ChineseCalendarStoreGenerations.activeDirectory(in: root) == root)
        ChineseCalendarStoreGenerations.abandon(pending, in: root)
    }

    @Test func repeatedBaseReplacementUsesIndependentFilesAndMetadata() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try autoreleasepool {
            let first = try ChineseCalendarStoreGenerations.prepare(in: root)
            let firstContainer = try makeStore(in: first, year: 2026, contentLevel: .base)
            try ChineseCalendarStoreGenerations.activate(first, in: root)
            let second = try ChineseCalendarStoreGenerations.prepare(in: root)
            let secondContainer = try makeStore(in: second, year: 2027, contentLevel: .base)
            try ChineseCalendarStoreGenerations.activate(second, in: root)
            try ChineseCalendarStoreGenerations.collectRetired(in: root)
            #expect(first != second)
            #expect(try ChineseCalendarModelContainerFactory.storeIdentityToken(at: storeURL(in: first)) == "2026")
            #expect(try ChineseCalendarModelContainerFactory.storeIdentityToken(at: storeURL(in: second)) == "2027")
            #expect(try ModelContext(firstContainer).fetch(FetchDescriptor<ChineseLunarYear>()).first?
                .lunarYearNumber == 2026)
            #expect(try ModelContext(secondContainer).fetch(FetchDescriptor<ChineseLunarYear>()).first?
                .lunarYearNumber == 2027)
        }
    }

    /// 在同一作用域内持有旧容器、Context 与月份，覆盖真实崩溃处的关系读取。
    private func verifyReplacement(in root: URL, legacy: Bool) throws -> URL {
        let first = try legacy ? root : ChineseCalendarStoreGenerations.prepare(in: root)
        let firstContainer = try makeStore(in: first, year: 2026, contentLevel: .full)
        if !legacy { try ChineseCalendarStoreGenerations.activate(first, in: root) }
        let context = ModelContext(firstContainer)
        let month = try #require(context.fetch(FetchDescriptor<ChineseLunarMonth>()).first)
        #expect(month.days.count == 1)
        let second = try ChineseCalendarStoreGenerations.prepare(in: root)
        let secondContainer = try makeStore(in: second, year: 2027, contentLevel: .base)
        try ChineseCalendarStoreGenerations.activate(second, in: root)
        try ChineseCalendarStoreGenerations.collectRetired(in: root)
        #expect(FileManager.default.fileExists(atPath: storeURL(in: first).path))
        #expect(ChineseCalendarRelationshipQueries.days(inMonth: month).map(\.dayIndex) == [2026])
        #expect(try ModelContext(secondContainer).fetch(FetchDescriptor<ChineseLunarDay>()).map(\.dayIndex) == [2027])
        #expect(try ChineseCalendarModelContainerFactory.storeContentLevel(at: storeURL(in: first)) == .full)
        withExtendedLifetime(firstContainer) {}
        return storeURL(in: first)
    }

    private func makeStore(
        in directory: URL,
        year: Int,
        contentLevel: ChineseCalendarSeedStoreContentLevel
    ) throws -> ModelContainer {
        let container = try ChineseCalendarModelContainerFactory.makeContainer(at: storeURL(in: directory))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let month = ChineseLunarMonth(
            lunarMonthIndex: year, monthNumberInYear: 1, isLeapMonth: false, dayCount: 30,
            monthStemIndex: 0, monthBranchIndex: 0,
            chineseLunarYear: ChineseLunarYear(lunarYearNumber: year, yearStemIndex: 0, yearBranchIndex: 0)
        )
        context.insert(ChineseLunarDay(
            dayIndex: year, dayNumberInMonth: 1, dayStemIndex: 0, dayBranchIndex: 0, chineseLunarMonth: month
        ))
        try context.save()
        let manifest = try JSONSerialization.data(withJSONObject: [
            "seedStoreContentLevel": contentLevel.rawValue, "artifactVersion": String(year)
        ])
        try manifest.write(to: directory.appendingPathComponent(ChineseCalendarSeedStore.manifestFileName))
        return container
    }

    private func storeURL(in directory: URL) -> URL {
        directory.appendingPathComponent(ChineseCalendarSeedStore.storeFileName)
    }

    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("StoreGenerationTests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
