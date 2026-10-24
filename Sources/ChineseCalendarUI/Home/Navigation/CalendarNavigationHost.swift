import NavigationCore
import SwiftData
import SwiftUI

/// 将导航宿主放在按数据库 identity 重建的页面内容之外。
/// 完整数据下载后切换 ModelContainer 时，原宿主仍能接收模态关闭通知并继续等待中的外部导航。
private struct CalendarNavigationHost: ViewModifier {
    let coordinator: CalendarHomeCoordinator
    let storeCoordinator: ChineseCalendarStoreCoordinator?

    func body(content: Content) -> some View {
        content
            .navigationHost(
                context: coordinator.router.navigation.rootPresentation,
                configuration: CalendarNavigationConfiguration(
                    coordinator: coordinator,
                    storeCoordinator: storeCoordinator
                )
            )
            .environment(coordinator)
            .environment(storeCoordinator)
            .onChange(of: storeCoordinator?.fullStoreDownloadProgress) { _, progress in
                if progress == nil { coordinator.downloadDetails.progressDidDisappear() }
            }
            .onChange(of: storeCoordinator?.downloadFailure, initial: true) { _, failure in
                if let failure, CalendarDownloadAlerts.presentFailure(failure, router: coordinator.router) {
                    storeCoordinator?.dismissDownloadError()
                }
            }
    }
}

extension View {
    func calendarNavigationHost(
        coordinator: CalendarHomeCoordinator,
        storeCoordinator: ChineseCalendarStoreCoordinator? = nil
    ) -> some View {
        modifier(CalendarNavigationHost(
            coordinator: coordinator,
            storeCoordinator: storeCoordinator
        ))
    }
}

extension ChineseCalendarStoreCoordinator {
    var navigationStoreIdentity: String? {
        guard case let .ready(container, contentLevel, identityToken) = state else { return nil }
        return storeIdentity(container: container, contentLevel: contentLevel, identityToken: identityToken)
    }
}
