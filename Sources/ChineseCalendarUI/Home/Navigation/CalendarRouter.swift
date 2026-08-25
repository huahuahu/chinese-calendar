import NavigationCore
import Observation

@MainActor
@Observable
final class CalendarRouter {
    let navigation: NavigationRouter<CalendarTab, CalendarDestination>
    @ObservationIgnored private var actionAfterPresentationDismissal: (() -> Void)?

    var selectedTab: CalendarTab {
        get { navigation.selectedScope }
        set { navigation.selectedScope = newValue }
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
        yearsPath: [CalendarDestination] = [],
        historyPath: [CalendarDestination] = []
    ) {
        navigation = NavigationRouter(
            selectedScope: selectedTab,
            paths: [.years: yearsPath, .history: historyPath]
        )
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

    func dismissFrontmostSheet(afterDismissal action: @escaping () -> Void) {
        actionAfterPresentationDismissal = action
        guard navigation.dismissFrontmostSheet() else {
            actionAfterPresentationDismissal = nil
            action()
            return
        }
    }

    func presentationHostDidDismiss() {
        _ = navigation.applyDeferredRequestIfReady()

        runActionAfterPresentationDismissal()
    }

    func presentationSubtreeDidDismiss() {
        runActionAfterPresentationDismissal()
    }

    private func runActionAfterPresentationDismissal() {
        let action = actionAfterPresentationDismissal
        actionAfterPresentationDismissal = nil
        action?()
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) -> NavigationRequestResult {
        navigation.submit(navigationRequest(for: deepLink))
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) -> NavigationRequestResult? {
        guard let deepLink else {
            return nil
        }

        return navigation.submit(navigationRequest(for: deepLink))
    }

    private func navigationRequest(
        for deepLink: CalendarDeepLink
    ) -> NavigationRequest<CalendarTab, CalendarDestination> {
        switch deepLink {
        case let .lunarYear(yearNumber, monthIndex):
            .replacePath([.lunarYear(yearNumber, monthIndex: monthIndex)], on: .years)
        case let .dynasty(dynastyID):
            .replacePath([.dynasty(dynastyID)], on: .history)
        case let .emperor(emperorID):
            .replacePath([.emperor(emperorID)], on: .history)
        }
    }
}
