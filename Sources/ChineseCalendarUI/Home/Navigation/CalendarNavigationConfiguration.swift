import NavigationCore
import SwiftUI

/// 日历导航树的 View 配置；具体页面的 selection、ModelContext 和回调仍由发起作用域提供。
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

    func presentationDidDismiss() {
        coordinator.releaseDismissedContexts()
    }
}
