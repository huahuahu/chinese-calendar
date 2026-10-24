import ChineseCalendarCore
import Foundation
import NavigationCore
import SwiftUI

/// 显示在应用根视图中，负责组织日历主页、导航与平台布局。
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
                storeCoordinator: settingsCoordinator,
                handlesExternalNavigation: true
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
