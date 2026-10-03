@testable import ChineseCalendarPersistence
import Foundation
import SwiftData
import Testing

@Suite("Persisted relationship schema")
struct RelationshipStoreTests {
    @Test func dayIdentityAndMonthDayUniquenessSurviveReopening() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite")
        do {
            let container = try ChineseCalendarModelContainerFactory.makeContainer(at: url)
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
            let firstMonth = makeMonth(index: 1, year: year)
            let secondMonth = makeMonth(index: 2, year: year)
            context.insert(firstMonth)
            context.insert(secondMonth)
            try context.save()

            context.insert(makeDay(index: 10, number: 1, month: firstMonth))
            try context.save()
            // A repeated absolute identity updates the existing day, even if its month-day slot changes.
            context.insert(makeDay(index: 10, number: 2, month: firstMonth))
            try context.save()
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ChineseLunarDay>()) == 1)

            // A different absolute identity cannot introduce a second row at the same month-day slot.
            context.insert(makeDay(index: 11, number: 2, month: firstMonth))
            try context.save()
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ChineseLunarDay>()) == 1)

            // The same day number is valid in a different month.
            context.insert(makeDay(index: 12, number: 2, month: secondMonth))
            try context.save()
        }
        let reopened = try ChineseCalendarModelContainerFactory.makeContainer(at: url, allowsSave: false)
        let context = ModelContext(reopened)
        let days = try context.fetch(FetchDescriptor<ChineseLunarDay>())
        #expect(days.count == 2)
        #expect(Set(days.compactMap { $0.chineseLunarMonth?.lunarMonthIndex }) == [1, 2])
        #expect(days.allSatisfy { $0.dayNumberInMonth == 2 })
    }

    @Test func relationshipPredicatesFollowReassignedParentsOnDisk() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let container = try ChineseCalendarModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("test.sqlite")
        )
        let context = ModelContext(container)
        let oldYear = ChineseLunarYear(lunarYearNumber: 2025, yearStemIndex: 1, yearBranchIndex: 5)
        let newYear = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let month = makeMonth(index: 1, year: oldYear)
        let day = makeDay(index: 10, number: 1, month: month)
        day.calendarDay = CalendarDay(dayIndex: 10, julianDayNumber: 2_461_063)
        context.insert(day)
        context.insert(newYear)
        try context.save()
        month.chineseLunarYear = newYear
        try context.save()
        let readContext = ModelContext(container)
        let yearNumber = 2026
        let monthIndex = 1
        #expect(try readContext.fetchCount(FetchDescriptor<ChineseLunarMonth>(
            predicate: ChineseCalendarRelationshipPredicates.months(inYear: yearNumber)
        )) == 1)
        #expect(try readContext.fetchCount(FetchDescriptor<ChineseLunarDay>(
            predicate: ChineseCalendarRelationshipPredicates.days(inMonth: monthIndex)
        )) == 1)
        try ChineseCalendarRelationshipValidation.validate(in: readContext)
    }

    @Test func incompleteRelationshipsAreRejected() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let container = try ChineseCalendarModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("test.sqlite")
        )
        let context = ModelContext(container)
        let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let month = makeMonth(index: 1, year: year)
        context.insert(month)
        try context.save()
        month.chineseLunarYear = nil
        try context.save()
        #expect(throws: ChineseCalendarRelationshipValidation.InvalidRelationships.self) {
            try ChineseCalendarRelationshipValidation.validate(in: ModelContext(container))
        }
    }

    @Test func oldRemoteManifestIsRejectedBeforeDownloading() throws {
        let manifest = FullSeedStoreManifest(
            datasetVersion: "old", schemaVersion: "1.2.0", seedStoreContentLevel: .full,
            seedStoreFormatVersion: 4, byteCount: 1, sha256: "unused",
            downloadURL: URL(fileURLWithPath: "/unused.sqlite")
        )
        #expect(throws: ChineseCalendarFullSeedStoreInstallError.self) {
            try ChineseCalendarFullSeedStoreInstaller.validate(manifest)
        }
    }

    @Test func indexedPredicatesSafelyExcludeMissingParents() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let container = try ChineseCalendarModelContainerFactory.makeContainer(
            at: directory.appendingPathComponent("test.sqlite")
        )
        let context = ModelContext(container)
        let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let month = makeMonth(index: 1, year: year)
        let day = makeDay(index: 10, number: 1, month: month)
        context.insert(day)
        try context.save()
        day.chineseLunarMonth = nil
        month.chineseLunarYear = nil
        try context.save()

        let dayPredicate = ChineseCalendarRelationshipPredicates.days(inMonth: 1)
        let monthPredicate = ChineseCalendarRelationshipPredicates.months(inYear: 2026)
        #expect(try !dayPredicate.evaluate(day))
        #expect(try !monthPredicate.evaluate(month))
        let readContext = ModelContext(container)
        #expect(try readContext.fetchCount(FetchDescriptor<ChineseLunarDay>(predicate: dayPredicate)) == 0)
        #expect(try readContext.fetchCount(FetchDescriptor<ChineseLunarMonth>(predicate: monthPredicate)) == 0)
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RelationshipStoreTests-\(UUID())")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeMonth(index: Int, year: ChineseLunarYear) -> ChineseLunarMonth {
        ChineseLunarMonth(
            lunarMonthIndex: index, monthNumberInYear: index, isLeapMonth: false, dayCount: 30,
            monthStemIndex: 0, monthBranchIndex: 0, chineseLunarYear: year
        )
    }

    private func makeDay(index: Int, number: Int, month: ChineseLunarMonth) -> ChineseLunarDay {
        ChineseLunarDay(
            dayIndex: index, dayNumberInMonth: number, dayStemIndex: 0, dayBranchIndex: 0,
            chineseLunarMonth: month
        )
    }
}
