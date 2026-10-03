import ChineseCalendarCore
import ChineseCalendarPersistence
import Foundation
import SwiftData

/// 构造稳定、无网络依赖的 Preview 示例数据。
enum PreviewSampleData {
    static let selectedDayIndex = 315

    private static let referenceDate = Date(timeIntervalSince1970: 1_769_083_200)

    static func makeContext(
        includesSampleData: Bool
    ) throws -> SampleDataPreviewContext {
        let modelContainer = try makeModelContainer(
            includesSampleData: includesSampleData
        )
        return SampleDataPreviewContext(
            modelContainer: modelContainer,
            selectedDayIndex: includesSampleData ? selectedDayIndex : nil,
            today: referenceDate
        )
    }

    static func makeModelContainer(
        includesSampleData: Bool = true
    ) throws -> ModelContainer {
        let schema = Schema(
            ChineseCalendarModelSchema.models,
            version: ChineseCalendarModelSchema.version
        )
        let configurationName = includesSampleData
            ? "SampleDataPreview-\(UUID().uuidString)"
            : "EmptySampleDataPreview-\(UUID().uuidString)"
        let configuration = ModelConfiguration(
            configurationName,
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        if includesSampleData {
            insertCalendarSample(into: container.mainContext)
            PreviewHistoricalCalendarData.insert(into: container.mainContext)
            insertHistorySample(into: container.mainContext)
            try container.mainContext.save()
        }

        return container
    }

    private static func insertCalendarSample(into context: ModelContext) {
        let year2025 = ChineseLunarYear(
            lunarYearNumber: 2025,
            yearStemIndex: 1,
            yearBranchIndex: 5
        )
        let year2026 = ChineseLunarYear(
            lunarYearNumber: 2026,
            yearStemIndex: 2,
            yearBranchIndex: 6
        )
        let year2027 = ChineseLunarYear(
            lunarYearNumber: 2027,
            yearStemIndex: 3,
            yearBranchIndex: 7
        )
        let populatedMonths = [
            makeMonth(index: 1, number: 11, dayCount: 29, year: year2025),
            makeMonth(index: 2, number: 12, dayCount: 30, year: year2025),
            makeMonth(index: 3, number: 1, dayCount: 30, year: year2026),
            makeMonth(index: 4, number: 2, dayCount: 29, year: year2026),
            makeMonth(index: 5, number: 2, isLeap: true, dayCount: 30, year: year2026)
        ]

        let todayJulianDayNumber = JulianDayNumber.forLocalGregorianDate(
            containing: referenceDate
        )
        var julianDayNumber = todayJulianDayNumber - 73

        for month in populatedMonths {
            julianDayNumber = insertDays(
                into: month,
                startingAt: julianDayNumber,
                context: context
            )
        }

        _ = makeMonth(index: 6, number: 1, dayCount: 30, year: year2027)

        context.insert(year2025)
        context.insert(year2026)
        context.insert(year2027)
    }

    private static func makeMonth(
        index: Int,
        number: Int,
        isLeap: Bool = false,
        dayCount: Int,
        year: ChineseLunarYear
    ) -> ChineseLunarMonth {
        let month = ChineseLunarMonth(
            lunarMonthIndex: index,
            lunarYearNumber: year.lunarYearNumber,
            monthNumberInYear: number,
            isLeapMonth: isLeap,
            dayCount: dayCount,
            monthStemIndex: (index - 1) % 10,
            monthBranchIndex: (index - 1) % 12,
            chineseLunarYear: year
        )
        year.months.append(month)
        return month
    }

    private static func insertDays(
        into month: ChineseLunarMonth,
        startingAt firstJulianDayNumber: Int,
        context: ModelContext
    ) -> Int {
        var julianDayNumber = firstJulianDayNumber

        for dayNumber in 1 ... month.dayCount {
            let dayIndex = month.lunarMonthIndex * 100 + dayNumber
            let calendarDay = CalendarDay(
                dayIndex: dayIndex,
                julianDayNumber: julianDayNumber
            )
            let lunarDay = ChineseLunarDay(
                dayIndex: dayIndex,
                lunarMonthIndex: month.lunarMonthIndex,
                dayNumberInMonth: dayNumber,
                dayStemIndex: (dayIndex - 1) % 10,
                dayBranchIndex: (dayIndex - 1) % 12,
                calendarDay: calendarDay,
                chineseLunarMonth: month
            )
            calendarDay.chineseLunarDay = lunarDay
            month.days.append(lunarDay)
            context.insert(calendarDay)
            julianDayNumber += 1
        }

        return julianDayNumber
    }

    private static func insertHistorySample(into context: ModelContext) {
        let sample = HistoryPreviewData.makeSample()
        context.insert(sample.tradition)
        context.insert(sample.dynasty)
        context.insert(sample.period)
    }
}
