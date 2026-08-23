import Observation

/// 协调日历主页的 deep link；具体页面状态由页面自己保存。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter

    init(router: CalendarRouter = CalendarRouter()) {
        self.router = router
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        _ = router.openDeepLink(deepLink)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) {
        _ = router.openColdLaunchDeepLink(deepLink)
    }
}
