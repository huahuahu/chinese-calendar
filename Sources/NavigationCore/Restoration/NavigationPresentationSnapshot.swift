import Foundation

/// 保存一个模态及其内部导航状态的数据副本，用于编码、比较和恢复。
///
/// 快照中只保存数据，不持有运行中的 Context 或可观察状态对象。
/// 子模态仍使用这个快照类型，所以用 indirect 支持逐层嵌套的结构。
public indirect enum NavigationPresentationSnapshot<
    Scope: Hashable,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 保存业务提示 ID 和路由；alert 没有导航栈，也没有子模态。
    case alert(NavigationAlertNode<AlertRoute>)

    /// id 标识这一次页面展示，destination 用于构建页面，style 指定展示方式。
    /// layer 保存页面内部各栈的路径，以及从这里继续打开的页面或业务提示。
    case node(
        id: UUID,
        destination: Destination,
        style: NavigationPresentationStyle,
        layer: NavigationLayerSnapshot<Scope, Destination, AlertRoute>
    )
}

extension NavigationPresentationSnapshot: Codable where Scope: Codable, Destination: Codable, AlertRoute: Codable {}
extension NavigationPresentationSnapshot: Equatable where Scope: Equatable, Destination: Equatable {}

extension NavigationPresentationNode {
    /// 复制当前模态及所有子模态的导航数据。生成的快照可在这些页面关闭后继续保存。
    var snapshot: NavigationPresentationSnapshot<Scope, Destination, AlertRoute> {
        .node(
            id: id, destination: destination, style: style,
            layer: NavigationLayerSnapshot(
                selectedStack: layer.selectedStack, rootDestinations: layer.roots,
                paths: layer.paths, presentation: layer.presentedContent?.snapshot
            )
        )
    }
}

extension NavigationPresentationSnapshot {
    var destinations: [Destination] {
        switch self {
        case let .node(_, destination, _, layer): [destination] + layer.destinations
        case .alert: []
        }
    }

    /// 检查整条模态链是否存在重复 ID，避免恢复后无法确定某个 ID 对应哪个模态。
    /// 页面数据是否仍存在、能否重新构建，由 App 另行检查。
    func validate(identities: inout Set<UUID>) -> Bool {
        switch self {
        case let .alert(node): return identities.insert(node.id).inserted
        case let .node(id, destination, _, layer):
            let hasValidRoots = if destination.providesNavigationContainer {
                layer.rootDestinations.values.allSatisfy { $0.supportsNavigationEntry(.stackRoot) }
            } else {
                layer.selectedStack == .primary && layer.rootDestinations == [.primary: destination] &&
                    layer.paths.keys.allSatisfy { $0 == .primary }
            }
            guard identities.insert(id).inserted,
                  destination.supportsNavigationEntry(.presentation),
                  layer.paths.values.joined().allSatisfy({ $0.supportsNavigationEntry(.push) }),
                  hasValidRoots
            else { return false }
            return layer.presentation?.validate(identities: &identities) ?? true
        }
    }

    /// 根据快照创建新的模态节点，并还原各层的导航栈和子模态。
    /// 节点沿用快照中的 UUID；层和栈使用新对象，也不恢复等待确认或等待关闭的状态。
    @MainActor
    func makePresentation() -> NavigationPresentation<Scope, Destination, AlertRoute> {
        switch self {
        case let .alert(alert): return .alert(alert)
        case let .node(id, destination, style, layer):
            let node = NavigationPresentationNode<Scope, Destination, AlertRoute>(
                id: id,
                destination: destination,
                style: style
            )
            node.layer.selectedStack = layer.selectedStack
            node.layer.roots = layer.rootDestinations
            node.layer.paths = layer.paths
            node.layer.presentedContent = layer.presentation?.makePresentation()
            return .page(node)
        }
    }
}

extension NavigationPresentation {
    var snapshot: NavigationPresentationSnapshot<Scope, Destination, AlertRoute> {
        switch self {
        case let .page(node): node.snapshot
        case let .alert(node): .alert(node)
        }
    }
}

public extension NavigationPresentationSnapshot {
    /// 业务提示的路由数据，可由 App 判断是否仍能安全重建。
    var alerts: [AlertRoute] {
        switch self {
        case let .alert(node): [node.destination]
        case let .node(_, _, _, layer): layer.presentation?.alerts ?? []
        }
    }
}
