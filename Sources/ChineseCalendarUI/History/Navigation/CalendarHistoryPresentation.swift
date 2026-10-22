import NavigationCore

extension CalendarPresentationContext {
    /// 独立历史容器只声明最后一栏的详情栈，前两栏由 App 管理选择。
    @discardableResult
    func presentHistory(style: NavigationPresentationStyle = .sheet) -> NavigationPresentationResult {
        present(.historyHome, style: style, rootDestinations: [.primary: .historyEmpty])
    }
}
