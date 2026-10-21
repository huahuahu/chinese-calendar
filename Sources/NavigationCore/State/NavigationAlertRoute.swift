// swiftformat:disable modifierOrder

/// 业务提示的路由数据。按钮返回 Action 数据，由 App 决定如何处理。
/// 路由和动作都不保存 View 或业务闭包。
nonisolated public protocol NavigationAlertRoute: Hashable {
    associatedtype Action: Hashable
}

/// 不使用业务提示的调用方可以将它作为 Router 的 AlertRoute 类型。
nonisolated public struct NoNavigationAlert: NavigationAlertRoute {
    public typealias Action = Never
    private init() {}
}
