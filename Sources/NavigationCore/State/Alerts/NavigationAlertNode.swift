import Foundation

/// 一次业务 alert 的身份与内容数据。alert 不拥有导航栈或下一层呈现。
struct NavigationAlertNode<Route: NavigationAlertRoute>: Identifiable {
    let id: NavigationAlertID
    let destination: Route
    let lifetime: NavigationPresentationLifetime

    init(id: NavigationAlertID = NavigationAlertID(), destination: Route) {
        self.init(id: id, destination: destination, lifetime: NavigationPresentationLifetime())
    }

    init(id: NavigationAlertID = NavigationAlertID(), destination: Route, lifetime: NavigationPresentationLifetime) {
        self.id = id
        self.destination = destination
        self.lifetime = lifetime
    }
}

extension NavigationAlertNode: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.destination == rhs.destination
    }
}
