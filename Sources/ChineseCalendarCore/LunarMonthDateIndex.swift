/// 从项目月份数据累计日期区间，不依赖系统农历规则。
public struct LunarMonthDateIndex: Sendable {
    /// 月序 0 的初一；数据集首日 JDN 1640703 是该月初四。
    public static let firstMonthStartJulianDayNumber = 1_640_700

    public struct Month: Equatable, Sendable {
        public let index: Int
        public let dayCount: Int

        public init(index: Int, dayCount: Int) {
            self.index = index
            self.dayCount = dayCount
        }
    }

    public struct DayPosition: Equatable, Sendable {
        public let monthIndex: Int
        public let dayNumberInMonth: Int
    }

    private let firstMonthIndex: Int
    private let boundaries: [Int]

    /// 月份须按连续月序排列；末项边界为最后一个月结束后的第一天。
    public init?(
        months: some Sequence<Month>,
        firstMonthIndex: Int = 0,
        firstMonthStartJulianDayNumber: Int = LunarMonthDateIndex.firstMonthStartJulianDayNumber
    ) {
        var boundaries = [firstMonthStartJulianDayNumber]
        var start = firstMonthStartJulianDayNumber
        var expectedIndex = firstMonthIndex
        for month in months {
            guard month.index == expectedIndex, (1 ... 30).contains(month.dayCount) else { return nil }
            let (end, overflow) = start.addingReportingOverflow(month.dayCount)
            let (nextIndex, indexOverflow) = expectedIndex.addingReportingOverflow(1)
            guard !overflow, !indexOverflow else { return nil }
            boundaries.append(end)
            start = end
            expectedIndex = nextIndex
        }
        guard boundaries.count > 1 else { return nil }
        self.firstMonthIndex = firstMonthIndex
        self.boundaries = boundaries
    }

    /// 在累计月长形成的半开区间中二分查找；无需先求年份、月号或闰月标记。
    public func day(forJulianDayNumber julianDayNumber: Int) -> DayPosition? {
        guard julianDayNumber >= boundaries[0], julianDayNumber < boundaries[boundaries.count - 1] else {
            return nil
        }
        var lower = 0
        var upper = boundaries.count - 1
        while lower + 1 < upper {
            let middle = lower + (upper - lower) / 2
            if boundaries[middle] <= julianDayNumber {
                lower = middle
            } else {
                upper = middle
            }
        }
        return DayPosition(
            monthIndex: firstMonthIndex + lower,
            dayNumberInMonth: julianDayNumber - boundaries[lower] + 1
        )
    }
}
