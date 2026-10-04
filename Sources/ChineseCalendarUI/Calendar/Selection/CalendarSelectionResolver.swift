import ChineseCalendarPersistence
import Foundation
import SwiftData

/// 把年月日导航意图解析为一个具体农历日，避免维护独立的当前年或当前月状态。
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

    /// 按年、月、日三种导航意图，确定目标的选中日。
    ///
    /// 年和月分别复用各自的默认日期规则；日按内部日序精确查询，不受今天影响。
    /// 目标缺少可用的日记录时返回 nil，不跨到其他导航粒度寻找替代日期。
    func selectedDayIndex(
        for landing: LunarCalendarLanding,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        switch landing {
        case let .year(yearNumber):
            try selectedDayIndex(
                inYear: yearNumber,
                todayJulianDayNumber: todayJulianDayNumber
            )
        case let .month(monthIndex):
            try selectedDayIndex(
                inMonth: monthIndex,
                todayJulianDayNumber: todayJulianDayNumber
            )
        case let .day(dayIndex):
            try lunarDay(for: dayIndex)?.dayIndex
        }
    }

    /// 为沿时间方向进入目标年份的场景，选择目标年边界月份中的一个日期。
    ///
    /// 向更早年份切换时进入目标年的最后一个月，向更晚年份切换时进入目标年的第一个月。
    /// 找到边界月后复用月内选择规则：今天在该月时选今天，否则选最早的日记录；缺少数据则返回 nil。
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

        guard let destinationMonth = try boundaryLunarMonth(inYear: yearNumber, order: order) else {
            return nil
        }

        return try selectedDayIndex(
            inMonth: destinationMonth.lunarMonthIndex,
            todayJulianDayNumber: todayJulianDayNumber
        )
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

    /// 从选中日推导所属农历年，供年份选择器高亮和切换方向判断使用。
    ///
    /// 先按日序查询有效农历日，再沿 chineseLunarMonth、chineseLunarYear 关系读取所属年份。
    /// 未提供日序、日记录不存在或民用日期及年月关系不完整时返回 nil。
    func yearNumber(forDayIndex dayIndex: Int?) throws -> Int? {
        guard let dayIndex,
              let selectedDay = try lunarDay(for: dayIndex),
              let selectedMonth = selectedDay.chineseLunarMonth
        else {
            return nil
        }

        return selectedMonth.chineseLunarYear?.lunarYearNumber
    }

    /// 将外部提供的“今天”儒略日数转换为可写入 CalendarSelection 的内部日序。
    ///
    /// 复用 lunarDay(forJulianDayNumber:) 查找民用日期关联的农历日，再返回它的 dayIndex；日期或关联缺失时返回 nil。
    /// 今天由 CalendarToday 等调用方提供，这里不读取系统时钟。
    func todayDayIndex(julianDayNumber: Int) throws -> Int? {
        try lunarDay(forJulianDayNumber: julianDayNumber)?.dayIndex
    }

    /// 检查已有选中日是否仍存在于当前数据中，供调用方决定是否需要重新解析初始选择。
    ///
    /// 复用按日序精确查询，要求日期存在且民用日期及年月关系完整；无效时返回 false，查询失败仍抛出错误。
    func contains(dayIndex: Int) throws -> Bool {
        try lunarDay(for: dayIndex) != nil
    }
}

private extension CalendarSelectionResolver {
    /// 为目标月份确定一个可选中的日序：今天在该月时选今天，否则选月内最早的日记录。
    ///
    /// 先通过今天的儒略日数查找有效农历日并核对所属月的月序，否则从目标月的 days 关系取日号最小的记录。
    /// 该月没有日级数据时返回 nil，不会仅凭月份信息生成选中日。
    func selectedDayIndex(
        inMonth monthIndex: Int,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        let today = try lunarDay(forJulianDayNumber: todayJulianDayNumber)
        if let today, today.chineseLunarMonth?.lunarMonthIndex == monthIndex {
            return today.dayIndex
        }

        return try firstLunarDay(inMonth: monthIndex)?.dayIndex
    }

    /// 为直接导航到某个农历年的场景确定默认选中日。
    ///
    /// 今天属于目标年时优先选今天；否则按连续农历月序找到该年的第一个月，再取其中最早的日记录。
    /// 目标年没有月份，或第一个月没有日记录时返回 nil；不会继续扫描该年的后续月份。
    func selectedDayIndex(
        inYear yearNumber: Int,
        todayJulianDayNumber: Int
    ) throws -> Int? {
        if let today = try lunarDay(forJulianDayNumber: todayJulianDayNumber) {
            let todayYearNumber = today.chineseLunarMonth?.chineseLunarYear?.lunarYearNumber
            if todayYearNumber == yearNumber {
                return today.dayIndex
            }
        }

        guard let firstMonth = try boundaryLunarMonth(inYear: yearNumber, order: .forward) else {
            return nil
        }

        return try firstLunarDay(inMonth: firstMonth.lunarMonthIndex)?.dayIndex
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

    /// 取得目标月中日号最小的有效农历日，作为该月的默认选中日。
    ///
    /// 先按连续月序找到月份，再通过 days 关系按日号排序，校验第一条记录的民用日期及年月关系。
    /// 完整数据下通常返回初一；月份不存在、没有日记录或首条记录关系不完整时返回 nil，不继续尝试后续日期。
    func firstLunarDay(inMonth monthIndex: Int) throws -> ChineseLunarDay? {
        var monthDescriptor = FetchDescriptor<ChineseLunarMonth>(
            predicate: #Predicate { $0.lunarMonthIndex == monthIndex }
        )
        monthDescriptor.fetchLimit = 1
        guard let month = try modelContext.fetch(monthDescriptor).first else { return nil }
        return validDay(ChineseCalendarRelationshipQueries.days(inMonth: month).first)
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
        var yearDescriptor = FetchDescriptor<ChineseLunarYear>(
            predicate: #Predicate { $0.lunarYearNumber == yearNumber }
        )
        yearDescriptor.fetchLimit = 1
        guard let year = try modelContext.fetch(yearDescriptor).first else { return nil }
        let months = ChineseCalendarRelationshipQueries.months(inYear: year)
        return order == .forward ? months.first : months.last
    }
}
