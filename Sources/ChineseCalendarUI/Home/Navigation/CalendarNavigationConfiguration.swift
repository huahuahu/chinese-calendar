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
        case let .clearDataFailed(id):
            return NavigationAlertDefinition(
                content: CalendarAlertContent.clearDataFailed(message: coordinator.alertMessages[id])
            ) { action in
                coordinator.handleNoticeAction(action, messageID: id)
            }
        case let .downloadFailed(id):
            return NavigationAlertDefinition(
                content: CalendarAlertContent.downloadFailed(message: coordinator.alertMessages[id])
            ) { action in
                coordinator.handleNoticeAction(action, messageID: id)
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
