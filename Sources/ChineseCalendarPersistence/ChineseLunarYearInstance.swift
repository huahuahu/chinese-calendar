import Foundation
import SwiftData

@Model
public final class ChineseLunarYearInstance {
    #Unique<ChineseLunarYearInstance>([\.id], [\.lunarYearNumber, \.startCalendarDayIndex])

    public var id: String
    public var lunarYearNumber: Int
    public var yearStem: String
    public var yearBranch: String
    public var startCalendarDayIndex: Int
    public var endCalendarDayIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \ChineseLunarMonthInstance.chineseLunarYearInstance)
    public var months: [ChineseLunarMonthInstance]

    public var yearStemBranch: StemBranch {
        StemBranch(stem: yearStem, branch: yearBranch)
    }

    public init(
        id: String,
        lunarYearNumber: Int,
        yearStem: String,
        yearBranch: String,
        startCalendarDayIndex: Int,
        endCalendarDayIndex: Int,
        months: [ChineseLunarMonthInstance] = []
    ) {
        self.id = id
        self.lunarYearNumber = lunarYearNumber
        self.yearStem = yearStem
        self.yearBranch = yearBranch
        self.startCalendarDayIndex = startCalendarDayIndex
        self.endCalendarDayIndex = endCalendarDayIndex
        self.months = months
    }
}
