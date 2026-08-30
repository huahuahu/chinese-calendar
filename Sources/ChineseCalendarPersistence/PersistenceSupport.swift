import Foundation
import SwiftData

public enum CivilCalendarStyle: String, Codable, CaseIterable, Sendable {
    case julian
    case gregorian
}

public enum ChineseCalendarModelSchema {
    public static let versionIdentifier = "1.2.0"
    public static let version = Schema.Version(1, 2, 0)

    public static let models: [any PersistentModel.Type] = [
        CalendarDay.self,
        CivilDate.self,
        ChineseLunarYear.self,
        ChineseLunarMonth.self,
        ChineseLunarDay.self,
        Dynasty.self,
        ChineseDateExpression.self,
        ChineseDateRange.self,
        ChineseDateBound.self,
        Emperor.self,
        EmperorReignSegment.self,
        ReignEra.self,
        OrthodoxTradition.self,
        OrthodoxBoundary.self,
        OrthodoxPeriod.self
    ]
}
