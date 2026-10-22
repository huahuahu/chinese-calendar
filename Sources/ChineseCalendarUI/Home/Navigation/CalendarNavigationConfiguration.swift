import NavigationCore
import SwiftUI

/// 为整棵日历导航树构建页面和提示，并处理 alert 按钮动作。
/// 年份选择器等页面所需的 selection、ModelContext 和回调，仍从打开它的页面所创建的会话取得。
struct CalendarNavigationConfiguration<BottomStatusBar: View>: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert

    let coordinator: CalendarHomeCoordinator
    let storeCoordinator: ChineseCalendarStoreCoordinator?
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    func destination(for destination: CalendarDestination) -> some View {
        CalendarDestinationView(
            destination: destination, bottomStatusBarIsPresented: bottomStatusBarIsPresented,
            bottomStatusBar: bottomStatusBar
        )
    }

    func confirmationContent(
        for request: NavigationRequest<CalendarTab, CalendarDestination>
    ) -> NavigationConfirmationContent? {
        CalendarNavigationConfirmation.content(for: request)
    }

    func alertContent(for route: CalendarAlert) -> NavigationAlertContent<CalendarAlert.Action>? {
        CalendarAlertContent.content(for: route, messages: coordinator.alertMessages)
    }

    func handleAlertAction(
        _ route: CalendarAlert, action: CalendarAlert.Action, presentation: CalendarPresentationContext
    ) async {
        await coordinator.handleAlertAction(route, action: action, presentation: presentation, store: storeCoordinator)
    }
}
