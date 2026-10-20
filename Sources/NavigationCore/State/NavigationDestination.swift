// swiftformat:disable modifierOrder

/// 页面声明承载需求；页面构建与业务状态仍由宿主负责。
nonisolated public protocol NavigationDestination: Hashable {
    /// true 表示页面组织自己的顶层容器，Core 不在外面重复包栈。
    var providesNavigationContainer: Bool { get }
    /// 页面需要 Core 提供的容器。自带顶层容器时，各子入口分别声明自己的需求。
    var navigationContainer: NavigationContainerKind { get }
    /// 页面允许出现的位置；容器页面还会被 Core 禁止作为普通栈根或 push 页面。
    var allowedNavigationEntries: Set<NavigationDestinationEntry> { get }
}

public extension NavigationDestination {
    var providesNavigationContainer: Bool {
        false
    }

    var navigationContainer: NavigationContainerKind {
        .stack
    }

    var allowedNavigationEntries: Set<NavigationDestinationEntry> {
        providesNavigationContainer ? [.root, .presentation] : [.root, .stackRoot, .presentation, .push]
    }

    /// 所有状态写入与恢复共用此检查，自带容器的页面仅能作为层入口。
    func supportsNavigationEntry(_ entry: NavigationDestinationEntry) -> Bool {
        guard allowedNavigationEntries.contains(entry) else { return false }
        if providesNavigationContainer { return entry == .root || entry == .presentation }
        return true
    }
}
