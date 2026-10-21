import Foundation
import SwiftData

@Model
public final class ChineseLunarYear {
    #Unique<ChineseLunarYear>([\.lunarYearNumber])

    public var lunarYearNumber: Int
    public var yearStemIndex: Int
    public var yearBranchIndex: Int

    /// 这个农历年包含的月份，与 ChineseLunarMonth.chineseLunarYear 互为反向关系。
    /// 删除此年时，级联删除其月份；数组本身不保证月份顺序。
    @Relationship(deleteRule: .cascade, inverse: \ChineseLunarMonth.chineseLunarYear)
    public var months: [ChineseLunarMonth]

    public init(
        lunarYearNumber: Int,
        yearStemIndex: Int,
        yearBranchIndex: Int,
        months: [ChineseLunarMonth] = []
    ) {
        self.lunarYearNumber = lunarYearNumber
        self.yearStemIndex = yearStemIndex
        self.yearBranchIndex = yearBranchIndex
        self.months = months
    }
}
