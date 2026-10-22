/// 系统提示宿主的身份同时包含来源，避免不同提示领域的相同底层值互相匹配。
nonisolated enum NavigationSystemAlertID: Hashable {
    case business(NavigationAlertID)
    case confirmation(NavigationConfirmationID)
}
