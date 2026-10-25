import ChineseCalendarPersistence
import Foundation
import SwiftData

/// 仅插入真实的年、月模型，不创建 CalendarDay 或 ChineseLunarDay。
enum PreviewBaseCalendarData {
    static let selectedMonthIndex = 3

    static func makeContext() throws -> SampleDataPreviewContext {
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let previousYear = ChineseLunarYear(lunarYearNumber: 2025, yearStemIndex: 1, yearBranchIndex: 5)
        let year = ChineseLunarYear(lunarYearNumber: 2026, yearStemIndex: 2, yearBranchIndex: 6)
        let nextYear = ChineseLunarYear(lunarYearNumber: 2027, yearStemIndex: 3, yearBranchIndex: 7)

        insertMonth(index: 1, number: 11, dayCount: 29, year: previousYear)
        insertMonth(index: 2, number: 12, dayCount: 30, year: previousYear)
        insertMonth(index: 3, number: 1, dayCount: 30, year: year)
        insertMonth(index: 4, number: 2, dayCount: 29, year: year)
        insertMonth(index: 5, number: 2, isLeap: true, dayCount: 30, year: year)
        insertMonth(index: 6, number: 1, dayCount: 30, year: nextYear)
        [previousYear, year, nextYear].forEach(container.mainContext.insert)
        try container.mainContext.save()

        return SampleDataPreviewContext(
            modelContainer: container,
            selection: .month(index: selectedMonthIndex),
            today: Date(timeIntervalSince1970: 1_769_083_200),
            contentLevel: .base
        )
    }

    private static func insertMonth(
        index: Int,
        number: Int,
        isLeap: Bool = false,
        dayCount: Int,
        year: ChineseLunarYear
    ) {
        let month = ChineseLunarMonth(
            lunarMonthIndex: index,
            monthNumberInYear: number,
            isLeapMonth: isLeap,
            dayCount: dayCount,
            monthStemIndex: (index - 1) % 10,
            monthBranchIndex: (index - 1) % 12,
            chineseLunarYear: year
        )
        year.months.append(month)
    }
}
