import ChineseCalendarCore
import Foundation
import NavigationCore
import SwiftUI

/// 显示在应用根视图中，负责组织日历主页、导航与平台布局。
public struct CalendarHomeView<BottomStatusBar: View>: View {
    @State private var coordinator = CalendarHomeCoordinator()
    private let settingsCoordinator: ChineseCalendarStoreCoordinator?
    private let bottomStatusBarIsPresented: Bool
    private let bottomStatusBar: () -> BottomStatusBar

    public init(
        settingsCoordinator: ChineseCalendarStoreCoordinator? = nil,
        bottomStatusBarIsPresented: Bool = false,
        @ViewBuilder bottomStatusBar: @escaping () -> BottomStatusBar
    ) {
        self.settingsCoordinator = settingsCoordinator
        self.bottomStatusBarIsPresented = bottomStatusBarIsPresented
        self.bottomStatusBar = bottomStatusBar
    }

    public var body: some View {
        NavigationRootView(context: coordinator.router.navigation.rootPresentation)
            .calendarNavigationHost(
                coordinator: coordinator,
                storeCoordinator: settingsCoordinator,
                handlesExternalNavigation: true,
                bottomStatusBarIsPresented: bottomStatusBarIsPresented, bottomStatusBar: bottomStatusBar
            )
    }
}

#Preview(traits: .sampleData) {
    CalendarHomeView()
}

public extension CalendarHomeView where BottomStatusBar == EmptyView {
    init(settingsCoordinator: ChineseCalendarStoreCoordinator? = nil) {
        self.settingsCoordinator = settingsCoordinator
        bottomStatusBarIsPresented = false
        bottomStatusBar = { EmptyView() }
    }

    @available(*, deprecated, message: "CalendarHomeView now selects the current lunar year automatically.")
    init(selectedDate _: ChineseCalendarDate?) {
        self.init()
    }
}
