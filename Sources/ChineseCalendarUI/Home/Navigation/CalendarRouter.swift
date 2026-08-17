import NavigationCore
import Observation

@MainActor
@Observable
final class CalendarRouter {
    let navigation: NavigationRouter<CalendarTab, CalendarDestination>
    private(set) var deferredDeepLink: CalendarDeepLink?

    var selectedTab: CalendarTab {
        get { navigation.selectedScope }
        set { navigation.selectedScope = newValue }
    }

    var yearsRootDestination: CalendarDestination? {
        navigation.rootDestination(for: .years)
    }

    var yearsPath: [CalendarDestination] {
        get { navigation.path(for: .years) }
        set { navigation.setPath(newValue, for: .years) }
    }

    var historyPath: [CalendarDestination] {
        get { navigation.path(for: .history) }
        set { navigation.setPath(newValue, for: .history) }
    }

    var sheet: CalendarPresentationNode? {
        get { navigation.sheet }
        set { navigation.sheet = newValue }
    }

    var fullScreen: CalendarPresentationNode? {
        get { navigation.fullScreen }
        set { navigation.fullScreen = newValue }
    }

    var selectedDestination: CalendarDestination? {
        currentDestination(on: selectedTab)
    }

    var hasActivePresentation: Bool {
        navigation.hasActivePresentation
    }

    init(
        selectedTab: CalendarTab = .years,
        yearsRootDestination: CalendarDestination? = nil,
        yearsPath: [CalendarDestination] = [],
        historyPath: [CalendarDestination] = []
    ) {
        var roots: [CalendarTab: CalendarDestination] = [:]
        roots[.years] = yearsRootDestination
        navigation = NavigationRouter(
            selectedScope: selectedTab,
            rootDestinations: roots,
            paths: [.years: yearsPath, .history: historyPath]
        )
    }

    func setYearsRootDestination(_ destination: CalendarDestination?) {
        navigation.setRootDestination(destination, for: .years)
    }

    func path(for tab: CalendarTab) -> [CalendarDestination] {
        tab == .settings ? [] : navigation.path(for: tab)
    }

    func setPath(_ path: [CalendarDestination], for tab: CalendarTab) {
        switch tab {
        case .years:
            navigation.setPath(path, for: .years)
        case .history:
            navigation.setPath(path, for: .history)
        case .settings:
            break
        }
    }

    func currentDestination(on tab: CalendarTab) -> CalendarDestination? {
        tab == .settings ? nil : navigation.currentDestination(on: tab)
    }

    func push(_ destination: CalendarDestination, on tab: CalendarTab? = nil) {
        let targetTab = tab ?? selectedTab
        guard targetTab != .settings else {
            return
        }
        navigation.push(destination, on: targetTab)
    }

    func presentSheet(_ destination: CalendarDestination) {
        navigation.presentSheet(destination)
    }

    func presentFullScreen(_ destination: CalendarDestination) {
        navigation.presentFullScreen(destination)
    }

    func dismissSheet() {
        navigation.dismissSheet()
    }

    func dismissFullScreen() {
        navigation.dismissFullScreen()
    }

    /// 返回 true 表示 deep link 已经立即改变导航；false 表示它正在等待 presentation 关闭。
    func openDeepLink(_ deepLink: CalendarDeepLink) -> Bool {
        guard !hasActivePresentation else {
            deferredDeepLink = deepLink
            dismissSheet()
            dismissFullScreen()
            return false
        }

        apply(deepLink)
        return true
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) -> Bool {
        guard let deepLink else {
            return false
        }

        apply(deepLink)
        return true
    }

    /// presentation 关闭后执行等待中的导航，并返回已应用的 deep link 供具体页面消费其输入。
    func applyDeferredDeepLinkIfReady() -> CalendarDeepLink? {
        guard !hasActivePresentation, let deferredDeepLink else {
            return nil
        }

        self.deferredDeepLink = nil
        apply(deferredDeepLink)
        return deferredDeepLink
    }

    private func apply(_ deepLink: CalendarDeepLink) {
        switch deepLink {
        case let .lunarYear(yearNumber, monthIndex):
            selectedTab = .years
            setYearsRootDestination(.lunarYear(yearNumber, monthIndex: monthIndex))
        case let .dynasty(dynastyID):
            selectedTab = .history
            setPath([.dynasty(dynastyID)], for: .history)
        case let .emperor(emperorID):
            selectedTab = .history
            setPath([.emperor(emperorID)], for: .history)
        }
    }
}
