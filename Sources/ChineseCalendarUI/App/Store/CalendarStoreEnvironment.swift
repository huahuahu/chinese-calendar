import ChineseCalendarPersistence
import SwiftUI

private struct CalendarStoreContentLevelKey: EnvironmentKey {
    static let defaultValue = ChineseCalendarSeedStoreContentLevel.base
}

extension EnvironmentValues {
    var calendarStoreContentLevel: ChineseCalendarSeedStoreContentLevel {
        get { self[CalendarStoreContentLevelKey.self] }
        set { self[CalendarStoreContentLevelKey.self] = newValue }
    }
}
