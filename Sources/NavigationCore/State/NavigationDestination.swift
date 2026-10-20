// swiftformat:disable modifierOrder

/// 页面声明承载需求；页面构建与业务状态仍由宿主负责。
nonisolated public protocol NavigationDestination: Hashable {
    /// true 表示页面组织自己的顶层容器（例如 TabView），Core 不在外面重复包栈。
    var providesNavigationContainer: Bool { get }
}

public extension NavigationDestination {
    var providesNavigationContainer: Bool {
        false
    }
}
