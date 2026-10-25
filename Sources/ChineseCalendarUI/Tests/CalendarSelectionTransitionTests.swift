import ChineseCalendarCore
import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("月日选择在浏览和换库之间保持当前位置")
struct CalendarSelectionTransitionTests {
    @Test func baseMonthBrowsingCrossesYearsAndDistinguishesLeapMonth() throws {
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let feature = makeFeature(in: base, landing: .month(index: 2))
        guard case let .yearPicker(_, binding, _) = try #require(feature.beginYearPicker()) else { return }
        #expect(feature.selection.value == .month(index: 2))
        #expect(binding.wrappedValue == 2025)
        #expect(try base.mainContext.fetchCount(FetchDescriptor<ChineseLunarDay>()) == 0)

        try feature.selectMonth(month(3, in: base), from: month(2, in: base))
        #expect(feature.selection.value == .month(index: 3))
        #expect(binding.wrappedValue == 2026)
        #expect(feature.yearTransitionContext.direction == .later)

        try feature.selectMonth(month(4, in: base), from: month(3, in: base))
        try feature.selectMonth(month(5, in: base), from: month(4, in: base))
        #expect(feature.selection.value == .month(index: 5))
        #expect(feature.selection.selectedDayIndex == nil)
        #expect(try month(5, in: base).isLeapMonth)

        try feature.selectMonth(month(2, in: base), from: month(5, in: base))
        #expect(feature.selection.value == .month(index: 2))
        #expect(binding.wrappedValue == 2025)
        #expect(feature.yearTransitionContext.direction == .earlier)
    }

    @Test func baseYearPickerCompletesAtSourceBoundaryAndUpdatesHighlight() throws {
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let feature = makeFeature(in: base, landing: .month(index: 4))
        guard case let .yearPicker(_, binding, _) = try #require(feature.beginYearPicker()) else { return }
        #expect(binding.wrappedValue == 2026)

        binding.wrappedValue = 2025
        #expect(feature.pendingYearTransition?.sourceMonthIndex == 3)
        #expect(feature.pendingYearTransition?.destinationMonthIndex == 2)
        #expect(feature.selection.value == .month(index: 4))
        #expect(binding.wrappedValue == 2026)

        feature.completeYearTransitionPreparation(5)
        #expect(feature.selection.value == .month(index: 4))
        feature.completeYearTransitionPreparation(3)
        #expect(feature.pendingYearTransition == nil)
        #expect(feature.selection.value == .month(index: 2))
        #expect(feature.selection.selectedDayIndex == nil)
        #expect(binding.wrappedValue == 2025)
    }

    @Test func installingFullDataResolvesDayInBrowsedMonthInsteadOfInitialLanding() throws {
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let full = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let landing = LunarCalendarLanding.month(index: 3)
        let feature = makeFeature(in: base, landing: landing)
        try feature.selectMonth(month(5, in: base), from: month(3, in: base))
        #expect(feature.selection.value == .month(index: 5))

        feature.connect(modelContext: full.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)

        #expect(feature.selection.value == .day(index: 501))
        #expect(feature.selection.selectedDayIndex == 501)
        #expect(feature.modelContext === full.mainContext)
    }

    @Test func clearingFullDataPreservesSelectedDaysMonth() throws {
        let full = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let landing = LunarCalendarLanding.day(index: 315)
        let feature = makeFeature(in: full, landing: landing)
        feature.selection.select(.day(index: 417))

        feature.connect(modelContext: base.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)

        #expect(feature.selection.value == .month(index: 4))
        #expect(feature.selection.selectedDayIndex == nil)
        guard case let .yearPicker(_, binding, context) = try #require(feature.beginYearPicker()) else { return }
        #expect(binding.wrappedValue == 2026)
        #expect(context === base.mainContext)
    }

    @Test func replacingFullDataPreservesExactSelectedDay() throws {
        let first = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let second = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let landing = LunarCalendarLanding.day(index: 315)
        let feature = makeFeature(in: first, landing: landing)
        feature.selection.select(.day(index: 417))

        feature.connect(modelContext: second.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)

        #expect(feature.selection.value == .day(index: 417))
        #expect(feature.modelContext === second.mainContext)
    }

    @Test func unresolvedExactDayRetriesWhenFullDataBecomesAvailable() throws {
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let full = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let landing = LunarCalendarLanding.day(index: 417)
        let feature = makeFeature(in: base, landing: landing)
        #expect(feature.selection.value == nil)
        feature.resolveSelectionIfNeeded(for: landing)
        #expect(feature.selection.value == nil)

        feature.connect(modelContext: full.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)

        #expect(feature.selection.value == .day(index: 417))
        #expect(feature.selection.selectedDayIndex == 417)
    }

    @Test func nonexistentExactDayNeverFallsBackToAnAvailableMonth() throws {
        let base = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let full = try SelectionTransitionFixture.makeContainer(includesDays: true)
        let landing = LunarCalendarLanding.day(index: 99999)
        let feature = makeFeature(in: base, landing: landing)
        #expect(feature.selection.value == nil)

        feature.connect(modelContext: full.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)
        feature.resolveSelectionIfNeeded(for: landing)

        #expect(feature.selection.value == nil)
        #expect(feature.selection.selectedDayIndex == nil)
        #expect(feature.pendingYearTransition == nil)
    }

    @Test func resolvedLandingDoesNotOverwriteLaterBrowsingOnRefreshOrStoreReplacement() throws {
        let first = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let second = try SelectionTransitionFixture.makeContainer(includesDays: false)
        let landing = LunarCalendarLanding.month(index: 3)
        let feature = makeFeature(in: first, landing: landing)
        try feature.selectMonth(month(4, in: first), from: month(3, in: first))

        feature.resolveSelectionIfNeeded(for: landing)
        #expect(feature.selection.value == .month(index: 4))
        feature.connect(modelContext: second.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)
        #expect(feature.selection.value == .month(index: 4))
    }

    private func makeFeature(in container: ModelContainer, landing: LunarCalendarLanding) -> CalendarYearFeature {
        let feature = CalendarYearFeature(today: CalendarToday(date: SelectionTransitionFixture.referenceDate))
        feature.connect(modelContext: container.mainContext, storeCoordinator: nil)
        feature.resolveSelectionIfNeeded(for: landing)
        return feature
    }

    private func month(_ index: Int, in container: ModelContainer) throws -> ChineseLunarMonth {
        let descriptor = FetchDescriptor<ChineseLunarMonth>(predicate: #Predicate { $0.lunarMonthIndex == index })
        return try #require(container.mainContext.fetch(descriptor).first)
    }
}

@MainActor
private enum SelectionTransitionFixture {
    static let referenceDate = Date(timeIntervalSince1970: 1_769_083_200)

    static func makeContainer(includesDays: Bool) throws -> ModelContainer {
        let schema = Schema(ChineseCalendarModelSchema.models, version: ChineseCalendarModelSchema.version)
        let configuration = ModelConfiguration(
            "SelectionTransition-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let year2025 = ChineseLunarYear(lunarYearNumber: 2025, yearStemIndex: 1, yearBranchIndex: 5)
        let year2026 = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let months = [
            makeMonth(index: 1, number: 11, dayCount: 29, year: year2025),
            makeMonth(index: 2, number: 12, dayCount: 30, year: year2025),
            makeMonth(index: 3, number: 1, dayCount: 30, year: year2026),
            makeMonth(index: 4, number: 2, dayCount: 29, year: year2026),
            makeMonth(index: 5, number: 2, isLeap: true, dayCount: 30, year: year2026)
        ]
        container.mainContext.insert(year2025)
        container.mainContext.insert(year2026)
        if includesDays {
            insertDays(into: months, context: container.mainContext)
        }
        try container.mainContext.save()
        return container
    }

    private static func makeMonth(
        index: Int, number: Int, isLeap: Bool = false, dayCount: Int, year: ChineseLunarYear
    ) -> ChineseLunarMonth {
        let month = ChineseLunarMonth(
            lunarMonthIndex: index, monthNumberInYear: number, isLeapMonth: isLeap, dayCount: dayCount,
            monthStemIndex: (index - 1) % 10, monthBranchIndex: (index - 1) % 12, chineseLunarYear: year
        )
        year.months.append(month)
        return month
    }

    private static func insertDays(into months: [ChineseLunarMonth], context: ModelContext) {
        var julianDayNumber = JulianDayNumber.forLocalGregorianDate(containing: referenceDate) - 73
        for month in months {
            for dayNumber in 1 ... month.dayCount {
                let dayIndex = month.lunarMonthIndex * 100 + dayNumber
                let day = CalendarDay(dayIndex: dayIndex, julianDayNumber: julianDayNumber)
                let lunarDay = ChineseLunarDay(
                    dayIndex: dayIndex, dayNumberInMonth: dayNumber,
                    dayStemIndex: (dayIndex - 1) % 10, dayBranchIndex: (dayIndex - 1) % 12,
                    calendarDay: day, chineseLunarMonth: month
                )
                day.chineseLunarDay = lunarDay
                month.days.append(lunarDay)
                context.insert(day)
                julianDayNumber += 1
            }
        }
    }
}
