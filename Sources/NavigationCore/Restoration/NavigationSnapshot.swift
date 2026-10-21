import Foundation

/// 保存整个 Router 的导航数据，包括选中的根 Tab、各栈的页面和嵌套模态。
///
/// Scope、Destination 和 AlertRoute 都支持 Codable 时，可以将快照编码保存。
/// 何时保存、存到哪里、如何升级旧格式，由 App 决定。
/// 快照包含当前业务提示路由，不包含 View、业务会话、排队请求、按钮动作或关闭动画状态。
/// App 还需检查路由数据能否重新构建页面，例如临时回调就无法仅凭 ID 恢复。
public struct NavigationSnapshot<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 构建 App 根界面时使用的 Destination。
    /// 例如根界面是 .tabs 时，各 Tab 栈的 .home、.history 另存于 layer.rootDestinations；
    /// 普通单栈中，这个值可以与栈底页面相同。
    public let rootDestination: Destination
    /// 根层与每个模态层共用相同的栈、路径和子呈现结构。
    public let layer: NavigationLayerSnapshot<Scope, Destination, AlertRoute>

    public init(
        rootDestination: Destination,
        layer: NavigationLayerSnapshot<Scope, Destination, AlertRoute>
    ) {
        self.rootDestination = rootDestination
        self.layer = layer
    }

    /// 命名栈容器的便利入口；普通单栈快照使用 layer 的 primary 栈。
    public init(
        rootDestination: Destination,
        selectedScope: Scope,
        rootDestinations: [Scope: Destination] = [:],
        paths: [Scope: [Destination]] = [:],
        presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>? = nil
    ) {
        self.init(
            rootDestination: rootDestination,
            layer: NavigationLayerSnapshot(
                selectedStack: .scope(selectedScope),
                rootDestinations: Dictionary(uniqueKeysWithValues: rootDestinations.map { (.scope($0.key), $0.value) }),
                paths: Dictionary(uniqueKeysWithValues: paths.map { (.scope($0.key), $0.value) }),
                presentation: presentation
            )
        )
    }

    /// 根层当前选中命名栈的 scope；选中 primary 时返回 nil，完整身份读取 layer.selectedStack。
    public var selectedScope: Scope? {
        guard case let .scope(scope) = layer.selectedStack else { return nil }
        return scope
    }

    /// 只包含 .scope(...) 命名栈的栈底页面，不包含 primary 栈。
    /// 包含所有栈的数据位于 layer.rootDestinations。
    public var rootDestinations: [Scope: Destination] {
        Dictionary(uniqueKeysWithValues: layer.rootDestinations.compactMap { key, value in
            guard case let .scope(scope) = key else { return nil }
            return (scope, value)
        })
    }

    /// 只包含 .scope(...) 命名栈的 push 路径；包含 primary 栈的数据位于 layer.paths。
    public var paths: [Scope: [Destination]] {
        Dictionary(uniqueKeysWithValues: layer.paths.compactMap { key, value in
            guard case let .scope(scope) = key else { return nil }
            return (scope, value)
        })
    }

    public var presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>? {
        layer.presentation
    }

    /// 收集快照中所有页面的路由数据，供 App 检查这些页面是否还能恢复。
    /// 结果可能重复，也不保证遍历顺序，不能把它当作用户访问页面的历史记录。
    public var destinations: [Destination] {
        [rootDestination] + layer.destinations
    }

    /// 根层和模态层共用结构校验；页面数据和外部容器配置由 App 检查。
    var hasValidPresentationTree: Bool {
        var identities = Set<UUID>()
        return layer.validate(for: rootDestination, identities: &identities)
    }
}

extension NavigationSnapshot: Codable where Scope: Codable, Destination: Codable, AlertRoute: Codable {}
extension NavigationSnapshot: Equatable where Scope: Equatable, Destination: Equatable {}

public extension NavigationRouter {
    /// 复制当前导航数据。读取不会改变页面，也不会等待正在进行的动画或业务操作。
    /// App 应选择合适的保存时机，并检查快照中的页面是否可以恢复。
    var snapshot: NavigationSnapshot<Scope, Destination, AlertRoute> {
        NavigationSnapshot(
            rootDestination: rootLayer.route.destination,
            layer: rootLayer.snapshot
        )
    }

    /// 用快照恢复根层各栈的状态，并重新创建模态及其内部各栈。
    ///
    /// 有模态尚未关闭、正在等待关闭完成、正在等待用户确认，或快照中有重复模态 ID 时，
    /// 返回 false，并保留当前全部导航数据。App 需提前检查页面数据是否仍可使用。
    /// 模态会沿用快照中的 ID，但使用新对象，所以旧模态 Context 仍然失效。
    /// rootDestination.providesNavigationContainer 不变时保留根层的栈对象；
    /// 在 Core 提供 NavigationStack 与页面自带 TabView／SplitView 等容器之间切换时，
    /// 会重建根层的栈，旧栈 Context 随之失效。
    /// - Returns: 全部导航数据恢复成功时返回 true；界面的展示动画可能尚未完成。
    @discardableResult
    func restore(_ snapshot: NavigationSnapshot<Scope, Destination, AlertRoute>) -> Bool {
        guard !hasActivePresentation, !isAwaitingPresentationDismissal, pendingConfirmation == nil, !hasActiveAlert,
              requestWaitingForAlert == nil,
              snapshot.hasValidPresentationTree else { return false }
        let resetsStacks = rootLayer.route.destination.providesNavigationContainer !=
            snapshot.rootDestination.providesNavigationContainer
        rootLayer.route = .root(destination: snapshot.rootDestination)
        rootLayer.restore(snapshot.layer, resetStacks: resetsStacks)
        contexts = contexts.filter(\.value.isActive)
        presentationContexts = presentationContexts.filter(\.value.isActive)
        return true
    }
}
