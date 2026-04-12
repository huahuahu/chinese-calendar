import ChineseCalendarCore
import Foundation
import SwiftData

@Model
public final class ChineseLunarMonthInstance {
    #Unique<ChineseLunarMonthInstance>([\.id], [\.chineseLunarYearInstanceID, \.monthNumberRawValue, \.isLeapMonth])

    public var id: String
    public var chineseLunarYearInstanceID: String
    public var monthNumberRawValue: Int
    public var isLeapMonth: Bool
    public var monthStem: String
    public var monthBranch: String
    public var startCalendarDayIndex: Int
    public var endCalendarDayIndex: Int

    public var chineseLunarYearInstance: ChineseLunarYearInstance?

    @Relationship(deleteRule: .cascade, inverse: \ChineseCalendarDay.chineseLunarMonthInstance)
    public var days: [ChineseCalendarDay]

    public var monthStemBranch: StemBranch {
        StemBranch(stem: monthStem, branch: monthBranch)
    }

    public var lunarMonth: LunarMonth? {
        guard let number = LunarMonthNumber(rawValue: monthNumberRawValue) else {
            return nil
        }

        return LunarMonth(number: number, isLeapMonth: isLeapMonth)
    }

    public init(
        id: String,
        chineseLunarYearInstanceID: String,
        monthNumberRawValue: Int,
        isLeapMonth: Bool,
        monthStem: String,
        monthBranch: String,
        startCalendarDayIndex: Int,
        endCalendarDayIndex: Int,
        chineseLunarYearInstance: ChineseLunarYearInstance? = nil,
        days: [ChineseCalendarDay] = []
    ) {
        self.id = id
        self.chineseLunarYearInstanceID = chineseLunarYearInstanceID
        self.monthNumberRawValue = monthNumberRawValue
        self.isLeapMonth = isLeapMonth
        self.monthStem = monthStem
        self.monthBranch = monthBranch
        self.startCalendarDayIndex = startCalendarDayIndex
        self.endCalendarDayIndex = endCalendarDayIndex
        self.chineseLunarYearInstance = chineseLunarYearInstance
        self.days = days
    }
}
