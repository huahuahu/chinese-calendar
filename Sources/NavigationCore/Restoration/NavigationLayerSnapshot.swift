/// 保存模态内部一层导航状态的数据副本，用于之后恢复。
///
/// 这里记录所有栈，包括未选中的 Tab，因此恢复后可以保留每个 Tab 的导航历史。
/// 模态本身的页面路由、ID 和展示方式保存在外层 NavigationPresentationSnapshot 中。
public struct NavigationLayerSnapshot<
    Scope: Hashable,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 这一层当前选中的栈。即使 paths 中没有它的记录，也可以选中它。
    public let selectedStack: NavigationStackID<Scope>
    /// 这一层各栈的根页面路由数据；模态本身的页面路由另存于外层节点。
    public let rootDestinations: [NavigationStackID<Scope>: Destination]
    /// 各栈已经 push 的页面列表，包含未选中的 Tab，每条列表均不含栈的根页面。
    public let paths: [NavigationStackID<Scope>: [Destination]]
    /// 从这一层打开的子模态快照，其中会继续保存更深层的模态。
    public let presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>?

    public init(
        selectedStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>? = nil
    ) {
        self.selectedStack = selectedStack
        self.rootDestinations = rootDestinations
        self.paths = paths
        self.presentation = presentation
    }

    var destinations: [Destination] {
        Array(rootDestinations.values) + paths.values.flatMap(\.self) + (presentation?.destinations ?? [])
    }
}

extension NavigationLayerSnapshot: Codable where Scope: Codable, Destination: Codable, AlertRoute: Codable {}
extension NavigationLayerSnapshot: Equatable where Scope: Equatable, Destination: Equatable {}
