import NavigationCore
import SwiftUI

/// 为整棵日历导航树提供构建入口，具体提示及按钮动作委托所属业务。
/// 每次页面需要的 Binding 和业务资源由路由传入。
struct CalendarNavigationConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert

    let coordinator: CalendarHomeCoordinator
    let storeCoordinator: ChineseCalendarStoreCoordinator?

    func destination(for destination: CalendarDestination) -> some View {
        CalendarDestinationView(destination: destination)
    }

    func confirmationContent(
        for request: NavigationRequest<CalendarTab, CalendarDestination>
    ) -> NavigationConfirmationContent? {
        CalendarNavigationConfirmation.content(for: request)
    }

    func alert(for route: CalendarAlert, presentation: CalendarPresentationContext) -> NavigationAlertDefinition? {
        switch route {
        case .clearDownloadedData:
            CalendarSettingsAlerts.clearDownloadedData(storeCoordinator: storeCoordinator, presentation: presentation)
        case .clearDataSucceeded:
            CalendarSettingsAlerts.clearDataSucceeded()
        case let .clearDataFailed(failure):
            CalendarSettingsAlerts.clearDataFailed(failure: failure)
        case let .downloadFailed(failure):
            CalendarDownloadAlerts.failed(failure: failure)
        #if DEBUG
            case let .debugNotice(number):
                CalendarDebugAlerts.notice(number: number)
            case .debugNavigationChoice:
                CalendarDebugAlerts.navigationChoice(router: coordinator.router)
        #endif
        }
    }
}
