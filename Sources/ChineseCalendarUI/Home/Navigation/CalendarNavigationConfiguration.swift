import NavigationCore
import SwiftUI

/// 为整棵日历导航树构建页面和提示，并处理 alert 按钮动作。
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
            let clearDownloadedData: (@MainActor () async throws -> Void)? = if let store = storeCoordinator {
                { try await store.clearDownloadedData() }
            } else {
                nil
            }
            return NavigationAlertDefinition(content: CalendarAlertContent.clearDownloadedData) { action in
                await coordinator.handleClearDownloadedDataAction(
                    action, presentation: presentation, clearDownloadedData: clearDownloadedData
                )
            }
        case .clearDataSucceeded:
            return NavigationAlertDefinition(content: CalendarAlertContent.clearDataSucceeded) { action in
                coordinator.handleNoticeAction(action)
            }
        case let .clearDataFailed(failure):
            return NavigationAlertDefinition(
                content: CalendarAlertContent
                    .clearDataFailed(message: CalendarStoreErrorPresentation.message(for: failure))
            ) { action in
                coordinator.handleNoticeAction(action)
            }
        case let .downloadFailed(failure):
            return NavigationAlertDefinition(
                content: CalendarAlertContent
                    .downloadFailed(message: CalendarStoreErrorPresentation.message(for: failure))
            ) { action in
                coordinator.handleNoticeAction(action)
            }
        #if DEBUG
            case let .debugNotice(number):
                return NavigationAlertDefinition(content: CalendarAlertContent.debugNotice(number: number)) { action in
                    coordinator.handleNoticeAction(action)
                }
            case .debugNavigationChoice:
                return NavigationAlertDefinition(content: CalendarAlertContent.debugNavigationChoice) { action in
                    coordinator.handleDebugNavigationAction(action)
                }
        #endif
        }
    }
}
