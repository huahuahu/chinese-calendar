import ChineseCalendarPersistence
import SwiftData
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

extension View {
    /// 覆盖整个导航树的数据环境；状态变化不替换呈现宿主的结构身份。
    func calendarStoreEnvironment(state: CalendarStoreBootstrapState) -> some View {
        transformEnvironment(\.self) { environment in
            if case let .ready(container, contentLevel, _) = state {
                environment.modelContext = container.mainContext
                environment.calendarStoreContentLevel = contentLevel
            }
        }
    }
}
