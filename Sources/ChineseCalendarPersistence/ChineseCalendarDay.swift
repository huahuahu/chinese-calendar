import ChineseCalendarCore
import Foundation
import SwiftData

@Model
public final class ChineseCalendarDay {
    #Unique<ChineseCalendarDay>([\.dayIndex], [\.julianDayNumber])

    public var dayIndex: Int
    public var julianDayNumber: Int
    public var dayStem: String
    public var dayBranch: String
    public var lunarDayRawValue: Int

    public var chineseLunarMonthInstance: ChineseLunarMonthInstance?

    @Relationship(deleteRule: .cascade, inverse: \CivilDateRecord.chineseCalendarDay)
    public var civilDateRecord: CivilDateRecord?

    @Relationship(deleteRule: .cascade, inverse: \ReignEraAssignment.chineseCalendarDay)
    public var reignEraAssignments: [ReignEraAssignment]

    public var dayStemBranch: StemBranch {
        StemBranch(stem: dayStem, branch: dayBranch)
    }

    public var lunarDay: LunarDay? {
        LunarDay(rawValue: lunarDayRawValue)
    }

    public init(
        dayIndex: Int,
        julianDayNumber: Int,
        dayStem: String,
        dayBranch: String,
        lunarDayRawValue: Int,
        chineseLunarMonthInstance: ChineseLunarMonthInstance? = nil,
        civilDateRecord: CivilDateRecord? = nil,
        reignEraAssignments: [ReignEraAssignment] = []
    ) {
        self.dayIndex = dayIndex
        self.julianDayNumber = julianDayNumber
        self.dayStem = dayStem
        self.dayBranch = dayBranch
        self.lunarDayRawValue = lunarDayRawValue
        self.chineseLunarMonthInstance = chineseLunarMonthInstance
        self.civilDateRecord = civilDateRecord
        self.reignEraAssignments = reignEraAssignments
    }
}
