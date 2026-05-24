import Foundation
import SwiftData

@Model
public final class ChineseLunarMonth {
    /// Some historical records have repeated month numbers within the same lunar year, so the import-stable month index
    /// is the only unique key.
    #Unique<ChineseLunarMonth>([\.lunarMonthIndex])

    public var lunarMonthIndex: Int
    public var lunarYearNumber: Int
    public var monthNumberInYear: Int
    public var isLeapMonth: Bool
    public var dayCount: Int
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
        dayCount: Int,
        monthStemIndex: Int,
        monthBranchIndex: Int,
        chineseLunarYear: ChineseLunarYear? = nil,
        days: [ChineseLunarDay] = []
    ) {
        self.lunarMonthIndex = lunarMonthIndex
        self.lunarYearNumber = lunarYearNumber
        self.monthNumberInYear = monthNumberInYear
        self.isLeapMonth = isLeapMonth
        self.dayCount = dayCount
        self.monthStemIndex = monthStemIndex
        self.monthBranchIndex = monthBranchIndex
        self.chineseLunarYear = chineseLunarYear
        self.days = days
    }
}
