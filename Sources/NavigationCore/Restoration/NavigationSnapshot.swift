import Foundation

/// 保存整个 Router 的导航数据，包括选中的根 Tab、各栈的页面和嵌套模态。
///
/// Scope、Destination 和 AlertRoute 都支持 Codable 时，可以将快照编码保存。
/// 何时保存、存到哪里、如何升级旧格式，由 App 决定。
/// 快照包含当前业务提示路由，不包含 View、业务会话、排队请求、按钮动作或关闭动画状态。
/// App 还需检查路由数据能否重新构建页面，例如临时回调就无法仅凭 ID 恢复。
public struct NavigationSnapshot<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute> {
    /// App 根界面选中的 Tab，与模态内部选中了哪个 Tab 无关。
    public let selectedScope: Scope
    /// 根层各栈保存的根页面路由数据；由界面直接构建的静态根页可以不提供。
    public let rootDestinations: [Scope: Destination]
    /// 根层各栈已经 push 的页面列表。模态内部的路径保存在模态自己的快照中。
    public let paths: [Scope: [Destination]]
    /// App 根层打开的模态及其所有子模态；没有模态时为 nil。
    public let presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>?

    public init(
        selectedScope: Scope,
        rootDestinations: [Scope: Destination] = [:],
        paths: [Scope: [Destination]] = [:],
        presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>? = nil
    ) {
        self.selectedScope = selectedScope
        self.rootDestinations = rootDestinations
        self.paths = paths
        self.presentation = presentation
    }

    /// 收集快照中所有页面的路由数据，供 App 检查这些页面是否还能恢复。
    /// 结果可能重复，也不保证遍历顺序，不能把它当作用户访问页面的历史记录。
    public var destinations: [Destination] {
        Array(rootDestinations.values) + paths.values.flatMap(\.self) + (presentation?.destinations ?? [])
    }

    /// 检查模态 ID 是否重复；不检查页面数据是否存在，也不检查 App 是否支持这些栈。
    var hasValidPresentationTree: Bool {
        var identities = Set<UUID>()
        return presentation?.validate(identities: &identities) ?? true
    }
}

extension NavigationSnapshot: Codable where Scope: Codable, Destination: Codable, AlertRoute: Codable {}
extension NavigationSnapshot: Equatable where Scope: Equatable, Destination: Equatable {}

public extension NavigationRouter {
    /// 复制当前导航数据。读取不会改变页面，也不会等待正在进行的动画或业务操作。
    /// App 应选择合适的保存时机，并检查快照中的页面是否可以恢复。
    var snapshot: NavigationSnapshot<Scope, Destination, AlertRoute> {
        NavigationSnapshot(
            selectedScope: selectedScope,
            rootDestinations: rootDestinations,
            paths: paths,
            presentation: rootLayer.presentedContent?.snapshot
        )
    }

    /// 用快照恢复根层各栈的状态，并重新创建模态及其内部各栈。
    ///
    /// 有模态尚未关闭、正在等待关闭完成、正在等待用户确认，或快照中有重复模态 ID 时，
    /// 返回 false，并保留当前全部导航数据。App 需提前检查页面数据是否仍可使用。
    /// 模态会沿用快照中的 ID，但使用新对象，所以旧模态 Context 仍然失效。
    /// 根层保留原来的栈对象，已有根 Tab Context 可以继续读写恢复后的路径。
    /// - Returns: 全部导航数据恢复成功时返回 true；界面的展示动画可能尚未完成。
    @discardableResult
    func restore(_ snapshot: NavigationSnapshot<Scope, Destination, AlertRoute>) -> Bool {
        guard !hasActivePresentation, !isAwaitingPresentationDismissal, pendingConfirmation == nil, !hasActiveAlert,
              requestWaitingForAlert == nil,
              snapshot.hasValidPresentationTree else { return false }
        selectedScope = snapshot.selectedScope
        rootLayer.roots = Dictionary(uniqueKeysWithValues: snapshot.rootDestinations.map { (.scope($0.key), $0.value) })
        paths = snapshot.paths
        rootLayer.presentedContent = snapshot.presentation?.makePresentation()
        contexts = contexts.filter(\.value.isActive)
        presentationContexts = presentationContexts.filter(\.value.isActive)
        return true
    }
}
