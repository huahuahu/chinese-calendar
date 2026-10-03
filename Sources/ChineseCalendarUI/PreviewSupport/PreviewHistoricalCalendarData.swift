import ChineseCalendarPersistence
import SwiftData

/// 摘取仓库已导入的古历数据，运行 Preview 时不读取磁盘上的原始数据。
/// 来源：Data/Processed/calendar_days/{-220,-219,0,1}/calendar_days.jsonl。
/// 月长、月干支和月首 JDN 保持原值；负数月序/日序仅供 Preview，避免与现代示例冲突。
/// 这里只包含选定的月份窗口，窗口之间的缺口不代表历史上月份相邻。
enum PreviewHistoricalCalendarData {
    private struct MonthSample {
        let index: Int
        let number: Int
        let count: Int
        let stem: Int
        let branch: Int
        let firstJulianDay: Int
        var isPost = false
    }

    static func insert(into context: ModelContext) {
        insertPostNinthMonth(into: context)
        insertEraBoundary(into: context)
    }

    private static func insertPostNinthMonth(into context: ModelContext) {
        let year = ChineseLunarYear(lunarYearNumber: -220, yearStemIndex: 6, yearBranchIndex: 4)
        let nextYear = ChineseLunarYear(lunarYearNumber: -219, yearStemIndex: 7, yearBranchIndex: 5)
        // 公元前 221 年：八月 → 九月 → 后九月 → 下一年的十月，保留古历岁首顺序。
        insertMonth(.init(
            index: -104,
            number: 8,
            count: 29,
            stem: 1,
            branch: 9,
            firstJulianDay: 1_640_937
        ), year: year, context: context)
        insertMonth(.init(
            index: -103,
            number: 9,
            count: 30,
            stem: 2,
            branch: 10,
            firstJulianDay: 1_640_966
        ), year: year, context: context)
        insertMonth(.init(
            index: -102,
            number: 9,
            count: 29,
            stem: 2,
            branch: 10,
            firstJulianDay: 1_640_996,
            isPost: true
        ), year: year, context: context)
        insertMonth(.init(
            index: -101,
            number: 10,
            count: 30,
            stem: 3,
            branch: 11,
            firstJulianDay: 1_641_025
        ), year: nextYear, context: context)
        context.insert(year)
        context.insert(nextYear)
    }

    private static func insertEraBoundary(into context: ModelContext) {
        let previousYear = ChineseLunarYear(lunarYearNumber: -1, yearStemIndex: 5, yearBranchIndex: 7)
        let year = ChineseLunarYear(lunarYearNumber: 0, yearStemIndex: 6, yearBranchIndex: 8)
        let nextYear = ChineseLunarYear(lunarYearNumber: 1, yearStemIndex: 7, yearBranchIndex: 9)
        insertMonth(.init(
            index: -15,
            number: 12,
            count: 30,
            stem: 3,
            branch: 1,
            firstJulianDay: 1_721_082
        ), year: previousYear, context: context)

        // 公元前 1 年完整的十二个月；公元 0 年是内部天文年号，不应作为显示名称。
        let dayCounts = [29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29]
        var firstJulianDay = 1_721_112
        for (offset, count) in dayCounts.enumerated() {
            insertMonth(.init(
                index: offset - 14,
                number: offset + 1,
                count: count,
                stem: (offset + 4) % 10,
                branch: (offset + 2) % 12,
                firstJulianDay: firstJulianDay
            ), year: year, context: context)
            firstJulianDay += count
        }

        insertMonth(.init(
            index: -2,
            number: 1,
            count: 30,
            stem: 6,
            branch: 2,
            firstJulianDay: 1_721_466
        ), year: nextYear, context: context)
        insertMonth(.init(
            index: -1,
            number: 2,
            count: 29,
            stem: 7,
            branch: 3,
            firstJulianDay: 1_721_496
        ), year: nextYear, context: context)
        [previousYear, year, nextYear].forEach(context.insert)
    }

    private static func insertMonth(
        _ sample: MonthSample,
        year: ChineseLunarYear,
        context: ModelContext
    ) {
        let month = ChineseLunarMonth(
            lunarMonthIndex: sample.index,
            lunarYearNumber: year.lunarYearNumber,
            monthNumberInYear: sample.number,
            isLeapMonth: sample.isPost,
            intercalaryMonthNameStyle: sample.isPost ? .post : .leap,
            dayCount: sample.count,
            monthStemIndex: sample.stem,
            monthBranchIndex: sample.branch,
            chineseLunarYear: year
        )
        year.months.append(month)
        for number in 1 ... sample.count {
            let dayIndex = sample.index * 100 + number
            let julianDay = sample.firstJulianDay + number - 1
            let calendarDay = CalendarDay(dayIndex: dayIndex, julianDayNumber: julianDay)
            let day = ChineseLunarDay(
                dayIndex: dayIndex,
                lunarMonthIndex: sample.index,
                dayNumberInMonth: number,
                dayStemIndex: (julianDay + 9) % 10,
                dayBranchIndex: (julianDay + 1) % 12,
                calendarDay: calendarDay,
                chineseLunarMonth: month
            )
            month.days.append(day)
            calendarDay.chineseLunarDay = day
            context.insert(calendarDay)
        }
    }
}
