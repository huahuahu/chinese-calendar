import Foundation

/// 一次业务 alert 的身份与内容数据。alert 不拥有导航栈或下一层呈现。
public struct NavigationAlertNode<Route: NavigationAlertRoute>: Identifiable {
    public let id: NavigationAlertID
    public let destination: Route

    public init(id: NavigationAlertID = NavigationAlertID(), destination: Route) {
        self.id = id
        self.destination = destination
    }
}

extension NavigationAlertNode: Equatable {}
