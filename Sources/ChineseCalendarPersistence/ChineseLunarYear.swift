import Foundation
import SwiftData

@Model
public final class ChineseLunarYear {
    #Unique<ChineseLunarYear>([\.lunarYearNumber])

    public var lunarYearNumber: Int
    public var yearStemIndex: Int
    public var yearBranchIndex: Int

    // One-to-many owner side for all lunar months in this lunar year.
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
