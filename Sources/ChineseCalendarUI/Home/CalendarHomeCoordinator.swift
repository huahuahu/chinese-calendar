import Observation

/// 协调日历主页的初始目的地与 deep link；具体页面状态由页面自己保存。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter

    init(router: CalendarRouter = CalendarRouter()) {
        self.router = router
    }

    func selectDefaultYearIfNeeded(availableYearNumbers yearNumbers: [Int], preferredYearNumber: Int) -> Int? {
        guard !yearNumbers.isEmpty else {
            return nil
        }

        let currentYearNumber = router.yearsRootDestination?.lunarYearNumber
        if let currentYearNumber, yearNumbers.contains(currentYearNumber) {
            return nil
        }

        if router.yearsRootDestination != nil, currentYearNumber == nil {
            return nil
        }

        let defaultYearNumber = yearNumbers.first { $0 == preferredYearNumber } ?? yearNumbers.last
        guard let defaultYearNumber else {
            return nil
        }

        let shouldSelectYearsTab = router.selectedDestination == nil
        router.setYearsRootDestination(.lunarYear(defaultYearNumber))
        if shouldSelectYearsTab {
            router.selectedTab = .years
        }
        return defaultYearNumber
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        _ = router.openDeepLink(deepLink)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) {
        _ = router.openColdLaunchDeepLink(deepLink)
    }
}
