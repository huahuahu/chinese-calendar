import ChineseCalendarCore
import Foundation
import SwiftData

@Model
public final class ChineseLunarMonth {
    // 同一农历年可能有重复月号，不能用“年 + 月号”唯一标识月份。
    // 使用导入数据中跨年份递增的 lunarMonthIndex 区分每一条月份记录。
    #Unique<ChineseLunarMonth>([\.lunarMonthIndex])

    public var lunarMonthIndex: Int
    public var monthNumberInYear: Int
    public var isLeapMonth: Bool
    public var intercalaryMonthNameStyleRawValue: String
    public var dayCount: Int
    public var monthStemIndex: Int
    public var monthBranchIndex: Int

    public var intercalaryMonthNameStyle: LunarIntercalaryMonthNameStyle {
        get { LunarIntercalaryMonthNameStyle(rawValue: intercalaryMonthNameStyleRawValue) ?? .leap }
        set { intercalaryMonthNameStyleRawValue = newValue.rawValue }
    }

    /// 此月所属的农历年，对应 ChineseLunarYear.months 中的这条月份记录。
    public var chineseLunarYear: ChineseLunarYear?

    /// 此月包含的农历日，与 ChineseLunarDay.chineseLunarMonth 互为反向关系。
    /// 删除此月时，级联删除这些日记录；数组本身不保证日期顺序。
    @Relationship(deleteRule: .cascade, inverse: \ChineseLunarDay.chineseLunarMonth)
    public var days: [ChineseLunarDay]

    public init(
        lunarMonthIndex: Int,
        monthNumberInYear: Int,
        isLeapMonth: Bool,
        intercalaryMonthNameStyle: LunarIntercalaryMonthNameStyle = .leap,
        dayCount: Int,
        monthStemIndex: Int,
        monthBranchIndex: Int,
        chineseLunarYear: ChineseLunarYear,
        days: [ChineseLunarDay] = []
    ) {
        self.lunarMonthIndex = lunarMonthIndex
        self.monthNumberInYear = monthNumberInYear
        self.isLeapMonth = isLeapMonth
        intercalaryMonthNameStyleRawValue = intercalaryMonthNameStyle.rawValue
        self.dayCount = dayCount
        self.monthStemIndex = monthStemIndex
        self.monthBranchIndex = monthBranchIndex
        self.chineseLunarYear = chineseLunarYear
        self.days = days
    }
}
