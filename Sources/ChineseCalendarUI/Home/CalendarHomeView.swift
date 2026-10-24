import ChineseCalendarCore
import NavigationCore
import SwiftUI

/// 日历根容器，负责组织页面并安装导航宿主。
public struct CalendarHomeView: View {
    @State private var coordinator = CalendarHomeCoordinator()
    private let settingsCoordinator: ChineseCalendarStoreCoordinator?

    public init(settingsCoordinator: ChineseCalendarStoreCoordinator? = nil) {
        self.settingsCoordinator = settingsCoordinator
    }

    public var body: some View {
        NavigationRootView(context: coordinator.router.navigation.rootPresentation)
            .calendarNavigationHost(
                coordinator: coordinator,
                storeCoordinator: settingsCoordinator
            )
    }
}

#Preview(traits: .sampleData) {
    CalendarHomeView()
}

public extension CalendarHomeView {
    @available(*, deprecated, message: "CalendarHomeView now selects the current lunar year automatically.")
    init(selectedDate _: ChineseCalendarDate?) {
        self.init()
    }
}
