import Foundation
import NavigationCore
import Observation

@MainActor
@Observable
final class CalendarRouter {
    let navigation: NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>

    /// 主标签页在任意层中使用同一组初始栈根，替换后的栈根、选中项与路径由该层单独保存。
    static var mainTabRoots: [NavigationStackID<CalendarTab>: CalendarDestination] {
        [.scope(.years): .calendarHome, .scope(.history): .historyEmpty, .scope(.settings): .settings]
    }

    var selectedTab: CalendarTab? {
        get {
            if case let .scope(tab) = navigation.rootPresentation.selectedStack { return tab }
            return nil
        }
        set {
            if let newValue { navigation.rootPresentation.selectedStack = .scope(newValue) }
        }
    }

    var yearsPath: [CalendarDestination] {
        get { navigation.rootPresentation.context(for: .scope(.years)).path }
        set { navigation.rootPresentation.context(for: .scope(.years)).path = newValue }
    }

    var historyPath: [CalendarDestination] {
        get { navigation.rootPresentation.context(for: .scope(.history)).path }
        set { navigation.rootPresentation.context(for: .scope(.history)).path = newValue }
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

    func openDeepLink(
        _ deepLink: CalendarDeepLink,
        confirmIfPresented: Bool = false
    ) -> NavigationRequestResult {
        navigation.submit(navigationRequest(for: deepLink), confirmIfPresented: confirmIfPresented)
    }

    private func navigationRequest(
        for deepLink: CalendarDeepLink
    ) -> NavigationRequest<CalendarTab, CalendarDestination> {
        switch deepLink {
        case let .lunarYear(yearNumber, monthIndex):
            .replacePath([.lunarYear(yearNumber, monthIndex: monthIndex)], on: .years)
        case let .dynasty(orthodoxPeriodID):
            .setRoot(.historyDetail(orthodoxPeriodID: orthodoxPeriodID, section: nil), on: .history)
        case let .emperor(emperorID):
            .setRoot(.emperor(emperorID), on: .history)
        }
    }
}
