import NavigationCore
import Observation
import SwiftUI

/// 负责应用级事件；页面流程由发起页面的 feature 自己持有。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter
    let downloadDetails = CalendarDownloadDetailsFeature()
    private var didOpenColdLaunchDeepLink = false

    init(router: CalendarRouter = CalendarRouter()) {
        self.router = router
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        _ = router.openDeepLink(deepLink, confirmIfPresented: true)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) {
        guard !didOpenColdLaunchDeepLink else { return }
        didOpenColdLaunchDeepLink = true
        _ = router.openColdLaunchDeepLink(deepLink)
    }

    func yearPickerConfiguration(
        feature: CalendarYearFeature, session: CalendarYearPickerSession,
        storeCoordinator: ChineseCalendarStoreCoordinator?
    ) -> some NavigationHostConfiguration<CalendarTab, CalendarDestination, CalendarAlert> {
        var configuration = CalendarNavigationConfiguration(
            coordinator: self, storeCoordinator: storeCoordinator,
            bottomStatusBarIsPresented: false, bottomStatusBar: { EmptyView() }
        )
        configuration.yearFeature = feature
        configuration.yearPickerSession = session
        return configuration
    }

    #if DEBUG
        func downloadPreviewConfiguration(
            state: FullStoreDownloadPreviewState, storeCoordinator: ChineseCalendarStoreCoordinator?
        ) -> some NavigationHostConfiguration<CalendarTab, CalendarDestination, CalendarAlert> {
            var configuration = CalendarNavigationConfiguration(
                coordinator: self, storeCoordinator: storeCoordinator,
                bottomStatusBarIsPresented: false, bottomStatusBar: { EmptyView() }
            )
            configuration.downloadPreviewState = state
            return configuration
        }
    #endif
}
