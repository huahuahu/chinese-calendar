import NavigationCore

/// 当前栈的 push/pop 入口；页面呈现单独读取 CalendarPresentationContext。
typealias CalendarNavigationContext = NavigationContext<CalendarTab, CalendarDestination>

/// 当前层的模态入口；各栈注入的入口共享层状态，并保留各自的发起栈身份。
typealias CalendarPresentationContext = NavigationPresentationContext<CalendarTab, CalendarDestination, CalendarAlert>

extension CalendarPresentationContext {
    /// 主标签页可从任何有效层打开，各 Tab 的选中项、路径和子模态互不共享。
    @discardableResult
    func presentMainTabs(
        style: NavigationPresentationStyle = .sheet,
        selectedTab: CalendarTab = .years,
        paths: [NavigationStackID<CalendarTab>: [CalendarDestination]] = [:]
    ) -> Bool {
        present(
            .mainTabs, style: style, initialStack: .scope(selectedTab),
            rootDestinations: CalendarRouter.mainTabRoots, paths: paths
        )
    }
}
