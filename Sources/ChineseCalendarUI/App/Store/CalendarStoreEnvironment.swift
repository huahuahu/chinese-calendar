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
    /// 为导航树提供就绪数据库的 ModelContext 和数据完整度。
    /// 通过修改 Environment 更新数据，不按存储状态创建不同的 View 分支，以保留导航宿主的生命周期。
    func calendarStoreEnvironment(state: CalendarStoreBootstrapState) -> some View {
        transformEnvironment(\.self) { environment in
            if case let .ready(container, contentLevel, _) = state {
                environment.modelContext = container.mainContext
                environment.calendarStoreContentLevel = contentLevel
            }
        }
    }
}
