import ChineseCalendarPersistence
import Foundation
import SwiftData

/// 把年月导航意图解析为一个具体农历日，避免维护独立的当前年或当前月状态。
struct CalendarSelectionResolver {
    let modelContext: ModelContext

    func selectedDayIndex(
        for landing: LunarCalendarLanding,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        if let dayIndex = landing.dayIndex, try day(dayIndex: dayIndex) != nil {
            return dayIndex
        }

        if let monthIndex = landing.monthIndex {
            let dayIndex = try selectedDayIndex(
                inMonth: monthIndex,
                todayJulianDayNumber: todayJulianDayNumber
            )
            if let dayIndex {
                return dayIndex
            }
        }

        return try selectedDayIndex(
            inYear: landing.yearNumber,
            todayJulianDayNumber: todayJulianDayNumber
        )
    }

    func selectedDayIndex(
        inMonth monthIndex: Int,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        let today = try todayDay(julianDayNumber: todayJulianDayNumber)
        if let today, today.chineseLunarMonth?.lunarMonthIndex == monthIndex {
            return today.dayIndex
        }

        return try firstDay(monthIndex: monthIndex)?.dayIndex
    }

    func selectedDayIndex(
        inYear yearNumber: Int,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        if let today = try todayDay(julianDayNumber: todayJulianDayNumber) {
            let todayYearNumber = today.chineseLunarMonth?.chineseLunarYear?.lunarYearNumber
            if todayYearNumber == yearNumber {
                return today.dayIndex
            }
        }

        guard let firstMonth = try boundaryMonth(yearNumber: yearNumber, order: .forward) else {
            return nil
        }

        return try firstDay(monthIndex: firstMonth.lunarMonthIndex)?.dayIndex
    }

    func selectedDayIndex(
        inBoundaryMonthOf yearNumber: Int,
        direction: LunarYearTransitionDirection,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        let order: SortOrder = switch direction {
        case .earlier:
            .reverse
        case .later:
            .forward
        }

        guard let destinationMonth = try boundaryMonth(yearNumber: yearNumber, order: order) else {
            return nil
        }

        return try selectedDayIndex(
            inMonth: destinationMonth.lunarMonthIndex,
            todayJulianDayNumber: todayJulianDayNumber
        )
    }

    func boundaryMonthIndex(
        inYear yearNumber: Int,
        direction: LunarYearTransitionDirection,
        isSource: Bool
    ) throws -> Int? {
        let order: SortOrder = switch (direction, isSource) {
        case (.earlier, true), (.later, false):
            .forward
        case (.later, true), (.earlier, false):
            .reverse
        }

        return try boundaryMonth(yearNumber: yearNumber, order: order)?.lunarMonthIndex
    }

    func adjacentMonth(
        to monthIndex: Int,
        direction: LunarYearTransitionDirection
    ) throws -> ChineseLunarMonth? {
        let descriptor: FetchDescriptor<ChineseLunarMonth> = switch direction {
        case .earlier:
            FetchDescriptor(
                predicate: #Predicate<ChineseLunarMonth> { month in
                    month.lunarMonthIndex < monthIndex
                },
                sortBy: [SortDescriptor(\.lunarMonthIndex, order: .reverse)]
            )
        case .later:
            FetchDescriptor(
                predicate: #Predicate<ChineseLunarMonth> { month in
                    month.lunarMonthIndex > monthIndex
                },
                sortBy: [SortDescriptor(\.lunarMonthIndex)]
            )
        }

        var limitedDescriptor = descriptor
        limitedDescriptor.fetchLimit = 1
        return try modelContext.fetch(limitedDescriptor).first
    }

    func yearNumber(forDayIndex dayIndex: Int?) throws -> Int? {
        guard let dayIndex,
              let selectedDay = try day(dayIndex: dayIndex),
              let selectedMonth = selectedDay.chineseLunarMonth
        else {
            return nil
        }

        return selectedMonth.chineseLunarYear?.lunarYearNumber
    }

    func monthIndex(forDayIndex dayIndex: Int?) throws -> Int? {
        guard let dayIndex else {
            return nil
        }

        return try day(dayIndex: dayIndex)?.chineseLunarMonth?.lunarMonthIndex
    }

    func todayDayIndex(julianDayNumber: Int) throws -> Int? {
        try todayDay(julianDayNumber: julianDayNumber)?.dayIndex
    }

    func contains(dayIndex: Int) throws -> Bool {
        try day(dayIndex: dayIndex) != nil
    }

    private func day(dayIndex: Int) throws -> ChineseLunarDay? {
        var descriptor = FetchDescriptor<ChineseLunarDay>(
            predicate: #Predicate<ChineseLunarDay> { day in
                day.dayIndex == dayIndex
            }
        )
        descriptor.fetchLimit = 1
        descriptor.relationshipKeyPathsForPrefetching = [\.calendarDay, \.chineseLunarMonth]
        return try validDay(modelContext.fetch(descriptor).first)
    }

    private func todayDay(julianDayNumber: Int) throws -> ChineseLunarDay? {
        var descriptor = FetchDescriptor<CalendarDay>(
            predicate: #Predicate<CalendarDay> { day in
                day.julianDayNumber == julianDayNumber
            }
        )
        descriptor.fetchLimit = 1
        descriptor.relationshipKeyPathsForPrefetching = [\.chineseLunarDay]
        return try validDay(modelContext.fetch(descriptor).first?.chineseLunarDay)
    }

    private func firstDay(monthIndex: Int) throws -> ChineseLunarDay? {
        var monthDescriptor = FetchDescriptor<ChineseLunarMonth>(
            predicate: #Predicate { $0.lunarMonthIndex == monthIndex }
        )
        monthDescriptor.fetchLimit = 1
        guard let month = try modelContext.fetch(monthDescriptor).first else { return nil }
        return validDay(ChineseCalendarRelationshipQueries.days(inMonth: month).first)
    }

    private func validDay(_ day: ChineseLunarDay?) -> ChineseLunarDay? {
        guard let day, day.calendarDay != nil, day.chineseLunarMonth?.chineseLunarYear != nil else {
            return nil
        }
        return day
    }

    private func boundaryMonth(
        yearNumber: Int,
        order: SortOrder
    ) throws -> ChineseLunarMonth? {
        var yearDescriptor = FetchDescriptor<ChineseLunarYear>(
            predicate: #Predicate { $0.lunarYearNumber == yearNumber }
        )
        yearDescriptor.fetchLimit = 1
        guard let year = try modelContext.fetch(yearDescriptor).first else { return nil }
        let months = ChineseCalendarRelationshipQueries.months(inYear: year)
        return order == .forward ? months.first : months.last
    }
}
