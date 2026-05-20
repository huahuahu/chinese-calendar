import Foundation
import SwiftData

public enum CivilCalendarStyle: String, Codable, CaseIterable, Sendable {
    case julian
    case gregorian
}

public enum ChineseCalendarModelSchema {
    public static let version = Schema.Version(1, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        CalendarDay.self,
        CivilDate.self,
        ChineseLunarYear.self,
        ChineseLunarMonth.self,
        ChineseLunarDay.self
    ]
}
