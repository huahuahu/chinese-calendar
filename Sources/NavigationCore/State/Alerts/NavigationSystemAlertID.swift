/// 区分业务 alert ID 和 confirmation ID，避免两类 ID 因底层值相同而被误认为同一次 alert。
nonisolated enum NavigationSystemAlertID: Hashable {
    case business(NavigationAlertID)
    case confirmation(NavigationConfirmationID)
}
