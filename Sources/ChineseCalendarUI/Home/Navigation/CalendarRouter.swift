import Foundation
import NavigationCore
import Observation

@MainActor
@Observable
final class CalendarRouter {
    let navigation: NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>

    /// 主标签页在任意层中使用同一组初始栈根，替换后的栈根、选中项与路径由该层单独保存。
    static var mainTabRoots: [NavigationStackID<CalendarTab>: CalendarDestination] {
        [.scope(.years): .calendarHome, .scope(.history): .historyHome, .scope(.settings): .settings]
    }

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
        navigation.sheet
    }

    var fullScreen: CalendarPresentationNode? {
        navigation.fullScreen
    }

    var selectedDestination: CalendarDestination? {
        currentDestination(on: selectedTab)
    }

    var hasActivePresentation: Bool {
        navigation.hasActivePresentation
    }

    var isAwaitingPresentationDismissal: Bool {
        navigation.isAwaitingPresentationDismissal
    }

    var presentations: [CalendarPresentationNode] {
        navigation.presentations
    }

    /// 示例恢复边界：只暴露可以从业务地址重新查询内容的导航树。
    var restorableSnapshot: NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>? {
        let snapshot = navigation.snapshot
        guard !isAwaitingPresentationDismissal, navigation.pendingConfirmation == nil,
              !navigation.hasActiveAlert, navigation.requestWaitingForAlert == nil,
              Self.hasValidContainerStructure(destination: snapshot.rootDestination, layer: snapshot.layer),
              snapshot.destinations.allSatisfy(\.supportsStateRestoration),
              snapshot.presentation?.alerts.isEmpty ?? true else { return nil }
        return snapshot
    }

    @discardableResult
    func restore(_ snapshot: NavigationSnapshot<CalendarTab, CalendarDestination, CalendarAlert>) -> Bool {
        guard snapshot.rootDestination == .mainTabs,
              Self.hasValidContainerStructure(destination: snapshot.rootDestination, layer: snapshot.layer),
              snapshot.destinations.allSatisfy(\.supportsStateRestoration),
              snapshot.presentation?.alerts.isEmpty ?? true else { return false }
        return navigation.restore(snapshot)
    }

    /// 自带容器需要业务定义的各 Tab 栈，栈根可以替换；每个模态使用相同规则检查。
    private static func hasValidContainerStructure(
        destination: CalendarDestination,
        layer: NavigationLayerSnapshot<CalendarTab, CalendarDestination, CalendarAlert>
    ) -> Bool {
        if destination == .mainTabs {
            guard Set(layer.rootDestinations.keys) == Set(mainTabRoots.keys),
                  mainTabRoots[layer.selectedStack] != nil,
                  layer.paths.keys.allSatisfy({ mainTabRoots[$0] != nil }) else { return false }
        }
        if case let .node(_, childDestination, _, childLayer) = layer.presentation {
            return hasValidContainerStructure(destination: childDestination, layer: childLayer)
        }
        return true
    }

    init(
        selectedTab: CalendarTab = .years,
        yearsPath: [CalendarDestination] = [],
        historyPath: [CalendarDestination] = []
    ) {
        navigation = NavigationRouter(
            rootDestination: .mainTabs, initialStack: .scope(selectedTab),
            rootDestinations: Self.mainTabRoots,
            paths: [.scope(.years): yearsPath, .scope(.history): historyPath]
        )
    }

    func path(for tab: CalendarTab) -> [CalendarDestination] {
        navigation.path(for: tab)
    }

    func setPath(_ path: [CalendarDestination], for tab: CalendarTab) {
        navigation.setPath(path, for: tab)
    }

    func currentDestination(on tab: CalendarTab) -> CalendarDestination? {
        navigation.currentDestination(on: tab)
    }

    func push(_ destination: CalendarDestination, on tab: CalendarTab? = nil) {
        navigation.push(destination, on: tab)
    }

    func presentSheet(_ destination: CalendarDestination) {
        guard !isAwaitingPresentationDismissal else { return }
        navigation.presentSheet(destination)
    }

    func presentFullScreen(
        _ destination: CalendarDestination, initialStack: NavigationStackID<CalendarTab> = .primary
    ) {
        guard !isAwaitingPresentationDismissal else { return }
        navigation.presentFullScreen(destination, initialStack: initialStack)
    }

    func dismissSheet() {
        navigation.dismissSheet()
    }

    func dismissFullScreen() {
        navigation.dismissFullScreen()
    }

    @discardableResult
    func dismissPresentation(id: UUID) -> Bool {
        navigation.dismissPresentation(id: id)
    }

    func rootPresentationDidDismiss() {
        navigation.presentationDidDismiss(isRoot: true)
    }

    func openDeepLink(
        _ deepLink: CalendarDeepLink,
        confirmIfPresented: Bool = false
    ) -> NavigationRequestResult {
        navigation.submit(navigationRequest(for: deepLink), confirmIfPresented: confirmIfPresented)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) -> NavigationRequestResult? {
        guard let deepLink else { return nil }
        return navigation.submit(navigationRequest(for: deepLink), confirmIfPresented: true)
    }

    private func navigationRequest(
        for deepLink: CalendarDeepLink
    ) -> NavigationRequest<CalendarTab, CalendarDestination> {
        switch deepLink {
        case let .lunarYear(yearNumber, monthIndex):
            .replacePath([.lunarYear(yearNumber, monthIndex: monthIndex)], on: .years)
        case let .dynasty(orthodoxPeriodID):
            .replacePath([.dynasty(orthodoxPeriodID: orthodoxPeriodID)], on: .history)
        case let .emperor(emperorID):
            .replacePath([.emperor(emperorID)], on: .history)
        }
    }
}
