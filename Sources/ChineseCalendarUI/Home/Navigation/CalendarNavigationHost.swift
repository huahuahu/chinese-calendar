import NavigationCore
import SwiftData
import SwiftUI

/// 根呈现宿主独立于数据页面的 identity，使下载完成和外部导航能跨越容器切换。
private struct CalendarNavigationHost<BottomStatusBar: View>: ViewModifier {
    let coordinator: CalendarHomeCoordinator
    let storeCoordinator: ChineseCalendarStoreCoordinator?
    let handlesExternalNavigation: Bool
    let bottomStatusBarIsPresented: Bool
    let bottomStatusBar: () -> BottomStatusBar

    func body(content: Content) -> some View {
        content
            .navigationHost(
                context: coordinator.router.navigation.rootPresentation,
                configuration: CalendarNavigationConfiguration(
                    coordinator: coordinator,
                    storeCoordinator: storeCoordinator,
                    bottomStatusBarIsPresented: bottomStatusBarIsPresented, bottomStatusBar: bottomStatusBar
                )
            )
            .environment(coordinator)
            .environment(storeCoordinator)
            .onChange(of: storeCoordinator?.navigationStoreIdentity, initial: true) {
                coordinator.storeIdentityDidChange(storeCoordinator?.navigationStoreIdentity)
            }
            .onChange(of: storeCoordinator?.fullStoreDownloadProgress) { _, progress in
                if progress == nil { coordinator.downloadProgressDidDisappear() }
            }
            .onChange(of: storeCoordinator?.downloadErrorMessage, initial: true) { _, message in
                if let message, coordinator.presentDownloadError(message) { storeCoordinator?.dismissDownloadError() }
            }
            .task {
                if handlesExternalNavigation {
                    coordinator.openColdLaunchDeepLink(
                        CalendarDeepLinkParser.deepLink(from: ProcessInfo.processInfo.arguments)
                    )
                }
            }
            .onOpenURL { url in
                guard handlesExternalNavigation, let deepLink = CalendarDeepLinkParser.deepLink(from: url) else {
                    return
                }
                coordinator.openDeepLink(deepLink)
            }
    }
}

extension View {
    func calendarNavigationHost(
        coordinator: CalendarHomeCoordinator,
        storeCoordinator: ChineseCalendarStoreCoordinator? = nil,
        handlesExternalNavigation: Bool = false
    ) -> some View {
        calendarNavigationHost(
            coordinator: coordinator, storeCoordinator: storeCoordinator,
            handlesExternalNavigation: handlesExternalNavigation, bottomStatusBarIsPresented: false
        ) { EmptyView() }
    }

    func calendarNavigationHost(
        coordinator: CalendarHomeCoordinator,
        storeCoordinator: ChineseCalendarStoreCoordinator? = nil,
        handlesExternalNavigation: Bool = false,
        bottomStatusBarIsPresented: Bool,
        @ViewBuilder bottomStatusBar: @escaping () -> some View
    ) -> some View {
        modifier(CalendarNavigationHost(
            coordinator: coordinator,
            storeCoordinator: storeCoordinator,
            handlesExternalNavigation: handlesExternalNavigation,
            bottomStatusBarIsPresented: bottomStatusBarIsPresented, bottomStatusBar: bottomStatusBar
        ))
    }
}

extension ChineseCalendarStoreCoordinator {
    var navigationStoreIdentity: String? {
        guard case let .ready(_, contentLevel, identityToken) = state else { return nil }
        return storeIdentity(contentLevel: contentLevel, identityToken: identityToken)
    }
}
