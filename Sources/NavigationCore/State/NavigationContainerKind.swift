// swiftformat:disable modifierOrder

/// Core 提供的导航结构；页面也可以自行组织顶层容器，并仅让 Core 承载其中的导航栈。
nonisolated public enum NavigationContainerKind: String, Codable, Hashable, Sendable {
    case stack
}
