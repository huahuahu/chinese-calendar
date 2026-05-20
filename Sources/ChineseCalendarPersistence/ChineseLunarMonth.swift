import Foundation
import SwiftData

@Model
public final class ChineseLunarMonth {
    #Unique<ChineseLunarMonth>([\.lunarMonthIndex], [\.lunarYearNumber, \.monthNumberInYear, \.isLeapMonth])

    public var lunarMonthIndex: Int
    public var lunarYearNumber: Int
    public var monthNumberInYear: Int
    public var isLeapMonth: Bool
    public var monthStemIndex: Int
    public var monthBranchIndex: Int

    /// Inverse side of ChineseLunarYear.months.
    public var chineseLunarYear: ChineseLunarYear?

    /// One-to-many owner side for all lunar days in this lunar month.
    @Relationship(deleteRule: .cascade, inverse: \ChineseLunarDay.chineseLunarMonth)
    public var days: [ChineseLunarDay]

    public init(
        lunarMonthIndex: Int,
        lunarYearNumber: Int,
        monthNumberInYear: Int,
        isLeapMonth: Bool,
        monthStemIndex: Int,
        monthBranchIndex: Int,
        chineseLunarYear: ChineseLunarYear? = nil,
        days: [ChineseLunarDay] = []
    ) {
        self.lunarMonthIndex = lunarMonthIndex
        self.lunarYearNumber = lunarYearNumber
        self.monthNumberInYear = monthNumberInYear
        self.isLeapMonth = isLeapMonth
        self.monthStemIndex = monthStemIndex
        self.monthBranchIndex = monthBranchIndex
        self.chineseLunarYear = chineseLunarYear
        self.days = days
    }
}
