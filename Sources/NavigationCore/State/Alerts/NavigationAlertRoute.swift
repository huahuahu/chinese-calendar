// swiftformat:disable modifierOrder

/// 业务提示的路由数据，只描述提示身份和业务载荷，不保存 View 或业务闭包。
/// 宿主配置分别配对各类提示的内容与同类型动作，不要求整棵树共享一个 Action。
nonisolated public protocol NavigationAlertRoute: Hashable, SendableMetatype {}

/// 不使用业务提示的调用方可以将它作为 Router 的 AlertRoute 类型。
nonisolated public struct NoNavigationAlert: NavigationAlertRoute {
    private init() {}
}
