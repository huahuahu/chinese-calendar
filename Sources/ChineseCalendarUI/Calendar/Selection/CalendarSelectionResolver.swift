import ChineseCalendarCore
import ChineseCalendarPersistence
import Foundation
import SwiftData

/// 把年月日导航意图解析为真实月份或日期，保持唯一业务浏览位置。
///
/// 这里只查询和返回结果，由调用方决定是否更新 CalendarSelection。
/// dayIndex 是应用内部日序，julianDayNumber 用于定位民用日期，两者不能直接互换。
/// 查询不到记录或日期关系不完整时返回 nil（存在性检查返回 false）；SwiftData 查询失败则抛出错误。
struct CalendarSelectionResolver {
    private let modelContext: ModelContext

    /// 注入查询所需的数据上下文；具体取数过程封装在解析器内部。
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 年月入口可在没有日记录时停留于月份；日入口必须精确命中，不能降级为月。
    func selection(
        for landing: LunarCalendarLanding,
        todayJulianDayNumber: Int
    ) throws -> CalendarSelectionValue? {
        switch landing {
        case .today:
            try todaySelection(julianDayNumber: todayJulianDayNumber)
        case let .year(yearNumber):
            try selection(inYear: yearNumber, todayJulianDayNumber: todayJulianDayNumber)
        case let .month(monthIndex):
            try lunarMonth(for: monthIndex).map {
                try defaultSelection(in: $0, todayJulianDayNumber: todayJulianDayNumber)
            }
        case let .day(dayIndex):
            try lunarDay(for: dayIndex).map { .day(index: $0.dayIndex) }
        }
    }

    /// 从当前浏览位置取得真实月份；月精度不要求日记录，日精度仍校验完整关系。
    func month(for selection: CalendarSelectionValue) throws -> ChineseLunarMonth? {
        switch selection {
        case let .month(index): try lunarMonth(for: index)
        case let .day(index): try lunarDay(for: index)?.chineseLunarMonth
        }
    }

    func yearNumber(for selection: CalendarSelectionValue) throws -> Int? {
        try month(for: selection)?.chineseLunarYear?.lunarYearNumber
    }

    func contains(selection: CalendarSelectionValue) throws -> Bool {
        try month(for: selection) != nil
    }

    /// 优先精确匹配今天的日记录；缺日时按连续月序累计真实月长定位月份。
    func todaySelection(julianDayNumber: Int) throws -> CalendarSelectionValue? {
        if let today = try lunarDay(forJulianDayNumber: julianDayNumber) {
            return .day(index: today.dayIndex)
        }
        return try todayLunarMonth(julianDayNumber: julianDayNumber).map { .month(index: $0.lunarMonthIndex) }
    }

    /// 为沿时间方向进入目标年份的场景，选择目标年的边界月份或其中的日期。
    ///
    /// 向更早年份进入末月，向更晚年份进入首月；无日记录时保留真实月份。
    func selection(
        inBoundaryMonthOf yearNumber: Int,
        direction: LunarYearTransitionDirection,
        todayJulianDayNumber: Int
    ) throws -> CalendarSelectionValue? {
        let order: SortOrder = switch direction {
        case .earlier: .reverse
        case .later: .forward
        }
        guard let month = try boundaryLunarMonth(inYear: yearNumber, order: order) else { return nil }
        return try defaultSelection(in: month, todayJulianDayNumber: todayJulianDayNumber)
    }

    /// 计算跨年切换时，月份条应离开或进入的边界月份，供滚动和过渡过程使用。
    ///
    /// 向更早年份切换：从源年的第一个月离开，进入目标年的最后一个月。
    /// 向更晚年份切换：从源年的最后一个月离开，进入目标年的第一个月。
    /// 将这两种方向和年份角色映射为升序或降序查询；该年没有月份时返回 nil。
    ///
    /// - Parameter isSource: true 表示查询即将离开的源年，false 表示查询即将进入的目标年。
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

        return try boundaryLunarMonth(inYear: yearNumber, order: order)?.lunarMonthIndex
    }

    /// 在全局农历月序中寻找当前月之前或之后最近的一条月份记录。
    ///
    /// 向更早月份查找时筛选较小的 lunarMonthIndex 并降序取一条；向更晚月份查找时筛选较大的索引并升序取一条。
    /// 使用连续月序而非月号，能够涵盖闰月、后月和跨年；数据有缺口时返回该方向最近的已有月。
    /// 当前月已处于数据范围边界、该方向没有记录时返回 nil。
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
}

private extension CalendarSelectionResolver {
    /// 月内优先今天，否则选最早的有效日；没有有效日时保留月份位置。
    func defaultSelection(
        in month: ChineseLunarMonth,
        todayJulianDayNumber: Int
    ) throws -> CalendarSelectionValue {
        let today = try lunarDay(forJulianDayNumber: todayJulianDayNumber)
        if let today, today.chineseLunarMonth?.lunarMonthIndex == month.lunarMonthIndex {
            return .day(index: today.dayIndex)
        }
        let firstDay = ChineseCalendarRelationshipQueries.days(inMonth: month).first { validDay($0) != nil }
        if let firstDay {
            return .day(index: firstDay.dayIndex)
        }
        return .month(index: month.lunarMonthIndex)
    }

    /// 今天属于目标年时优先定位当天或当月，其余年份按连续月序进入首月。
    func selection(
        inYear yearNumber: Int,
        todayJulianDayNumber: Int
    ) throws -> CalendarSelectionValue? {
        let today = try todaySelection(julianDayNumber: todayJulianDayNumber)
        let todayMonth = try today.flatMap { try month(for: $0) }
        if let todayMonth, todayMonth.chineseLunarYear?.lunarYearNumber == yearNumber {
            return try defaultSelection(in: todayMonth, todayJulianDayNumber: todayJulianDayNumber)
        }
        guard let firstMonth = try boundaryLunarMonth(inYear: yearNumber, order: .forward) else {
            return nil
        }
        return try defaultSelection(in: firstMonth, todayJulianDayNumber: todayJulianDayNumber)
    }

    /// 月表包含完整月长，即使没有逐日记录，也可从数据集月初锚点累计定位。
    func todayLunarMonth(julianDayNumber: Int) throws -> ChineseLunarMonth? {
        var descriptor = FetchDescriptor<ChineseLunarMonth>(sortBy: [SortDescriptor(\.lunarMonthIndex)])
        descriptor.propertiesToFetch = [\.lunarMonthIndex, \.dayCount]
        let months = try modelContext.fetch(descriptor)
        let lengths = months.lazy.map { LunarMonthDateIndex.Month(index: $0.lunarMonthIndex, dayCount: $0.dayCount) }
        guard let dateIndex = LunarMonthDateIndex(months: lengths),
              let position = dateIndex.day(forJulianDayNumber: julianDayNumber)
        else {
            return nil
        }
        return try lunarMonth(for: position.monthIndex)
    }

    /// 按内部日序取得一条农历日记录，作为日期选择和所属年月推导的基础查询。
    ///
    /// 使用 dayIndex 等值筛选并限制最多返回一条，同时预取民用日期和所属月份关系，供后续读取。
    /// 没有匹配记录，或 validDay(_:) 判定其关系不完整时返回 nil。
    func lunarDay(for dayIndex: Int) throws -> ChineseLunarDay? {
        var descriptor = FetchDescriptor<ChineseLunarDay>(
            predicate: #Predicate<ChineseLunarDay> { day in
                day.dayIndex == dayIndex
            }
        )
        descriptor.fetchLimit = 1
        descriptor.relationshipKeyPathsForPrefetching = [\.calendarDay, \.chineseLunarMonth]
        return try validDay(modelContext.fetch(descriptor).first)
    }

    /// 从指定民用日期找到对应的农历日，为“今天优先”的选择规则提供数据。
    ///
    /// 按 julianDayNumber 精确查询 CalendarDay，最多取一条并预取 chineseLunarDay 关系。
    /// 返回通过 validDay(_:) 校验的关联农历日；日期不存在或民用日期及年月关系不完整时返回 nil。
    func lunarDay(forJulianDayNumber julianDayNumber: Int) throws -> ChineseLunarDay? {
        var descriptor = FetchDescriptor<CalendarDay>(
            predicate: #Predicate<CalendarDay> { day in
                day.julianDayNumber == julianDayNumber
            }
        )
        descriptor.fetchLimit = 1
        descriptor.relationshipKeyPathsForPrefetching = [\.chineseLunarDay]
        return try validDay(modelContext.fetch(descriptor).first?.chineseLunarDay)
    }

    /// 月份必须存在且关联真实年份；没有日记录不影响月精度浏览。
    func lunarMonth(for monthIndex: Int) throws -> ChineseLunarMonth? {
        var monthDescriptor = FetchDescriptor<ChineseLunarMonth>(
            predicate: #Predicate { $0.lunarMonthIndex == monthIndex }
        )
        monthDescriptor.fetchLimit = 1
        guard let month = try modelContext.fetch(monthDescriptor).first,
              month.chineseLunarYear != nil else { return nil }
        return month
    }

    /// 校验选中日是否具备页面展示和年月推导所需的完整关系。
    ///
    /// 日期必须关联民用日期、所属农历月及所属农历年；任何关系缺失都返回 nil，避免产生无效的日历位置。
    func validDay(_ day: ChineseLunarDay?) -> ChineseLunarDay? {
        guard let day, day.calendarDay != nil, day.chineseLunarMonth?.chineseLunarYear != nil else {
            return nil
        }
        return day
    }

    /// 取得指定农历年在时间顺序上的第一个月或最后一个月，统一各类年份边界查询。
    ///
    /// 先按 lunarYearNumber 找到农历年，再通过 months 关系按连续月序排序，取对应方向的边界月。
    /// order 为 .forward 时取首月，为 .reverse 时取末月；使用连续月序以保留古历年首、闰月和后月的顺序。
    /// 该年没有月份记录时返回 nil。
    func boundaryLunarMonth(
        inYear yearNumber: Int,
        order: SortOrder
    ) throws -> ChineseLunarMonth? {
        guard let year = try lunarYear(for: yearNumber) else { return nil }
        let months = ChineseCalendarRelationshipQueries.months(inYear: year)
        return order == .forward ? months.first : months.last
    }

    func lunarYear(for yearNumber: Int) throws -> ChineseLunarYear? {
        var yearDescriptor = FetchDescriptor<ChineseLunarYear>(
            predicate: #Predicate { $0.lunarYearNumber == yearNumber }
        )
        yearDescriptor.fetchLimit = 1
        return try modelContext.fetch(yearDescriptor).first
    }
}
