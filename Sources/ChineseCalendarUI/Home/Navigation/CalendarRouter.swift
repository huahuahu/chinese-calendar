import Observation

@MainActor
@Observable
final class CalendarRouter {
    var selectedTab: CalendarTab
    var yearsRootDestination: CalendarDestination?
    var yearsPath: [CalendarDestination]
    var historyPath: [CalendarDestination]
    var sheet: CalendarPresentationNode?
    var fullScreen: CalendarPresentationNode?
    private(set) var deferredDeepLink: CalendarDeepLink?

    var selectedDestination: CalendarDestination? {
        currentDestination(on: selectedTab)
    }

    var hasActivePresentation: Bool {
        sheet != nil || fullScreen != nil
    }

    init(
        selectedTab: CalendarTab = .years,
        yearsRootDestination: CalendarDestination? = nil,
        yearsPath: [CalendarDestination] = [],
        historyPath: [CalendarDestination] = []
    ) {
        self.selectedTab = selectedTab
        self.yearsRootDestination = yearsRootDestination
        self.yearsPath = yearsPath
        self.historyPath = historyPath
    }

    func setYearsRootDestination(_ destination: CalendarDestination?) {
        yearsRootDestination = destination
        yearsPath.removeAll()
    }

    func path(for tab: CalendarTab) -> [CalendarDestination] {
        switch tab {
        case .years:
            yearsPath
        case .history:
            historyPath
        case .settings:
            []
        }
    }

    func setPath(_ path: [CalendarDestination], for tab: CalendarTab) {
        switch tab {
        case .years:
            yearsPath = path
        case .history:
            historyPath = path
        case .settings:
            break
        }
    }

    func currentDestination(on tab: CalendarTab) -> CalendarDestination? {
        switch tab {
        case .years:
            yearsPath.last ?? yearsRootDestination
        case .history:
            historyPath.last
        case .settings:
            nil
        }
    }

    func push(_ destination: CalendarDestination, on tab: CalendarTab? = nil) {
        let targetTab = tab ?? selectedTab
        selectedTab = targetTab
        var path = path(for: targetTab)
        path.append(destination)
        setPath(path, for: targetTab)
    }

    func presentSheet(_ destination: CalendarDestination) {
        if let presentationNode = frontmostPresentationNode {
            presentationNode.presentSheet(destination)
        } else {
            sheet = CalendarPresentationNode(destination: destination)
        }
    }

    func presentFullScreen(_ destination: CalendarDestination) {
        if let presentationNode = frontmostPresentationNode {
            presentationNode.presentFullScreen(destination)
        } else {
            fullScreen = CalendarPresentationNode(destination: destination)
        }
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
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

    private var frontmostPresentationNode: CalendarPresentationNode? {
        if let fullScreen {
            return fullScreen.frontmostPresentationNode
        }

        if let sheet {
            return sheet.frontmostPresentationNode
        }

        return nil
    }
}
