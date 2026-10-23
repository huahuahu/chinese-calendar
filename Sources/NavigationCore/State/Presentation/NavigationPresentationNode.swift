import Foundation
import Observation

/// 记录一个已经加入导航状态的模态：展示什么页面、怎样展示，以及它内部的导航状态。
///
/// 父层通过 presentation 持有这个节点。节点的 layer 保存内部各栈的路径和子模态，
/// 因此一个模态可以继续打开另一个模态。每次通过 present 打开页面都会生成新的节点 ID。
/// 页面可读取这些属性；修改路径或打开、关闭模态时，使用对应的 Context。
@MainActor
@Observable
final class NavigationPresentationNode<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
>: Identifiable {
    /// 这一次打开模态的 ID，用于 SwiftUI 展示和指定关闭目标。
    var id: NavigationPresentationID {
        guard case let .presentation(id) = layer.id else {
            preconditionFailure("A presentation node requires a presentation layer")
        }
        return id
    }

    /// 打开整个模态时使用的 Destination，例如包含多个 Tab 的 .tabs。
    /// 模态内各栈的栈底页面和 push 路径另存于栈状态；修改它们不会改变此属性。
    var destination: Destination {
        layer.route.destination
    }

    /// 这个模态使用 sheet 还是全屏方式展示。
    let style: NavigationPresentationStyle
    let layer: NavigationLayer<Scope, Destination, AlertRoute>
    let lifetime: NavigationPresentationLifetime
    /// 页面已实际关闭，但后代 alert 动作可能仍需完成后才能释放整棵子树。
    var didCompletePhysicalDismissal = false

    convenience init(
        id: NavigationPresentationID = NavigationPresentationID(), destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        lifetime: NavigationPresentationLifetime = NavigationPresentationLifetime()
    ) {
        guard let layer = NavigationLayer<Scope, Destination, AlertRoute>(
            route: .presentation(id: id, destination: destination), initialStack: initialStack,
            rootDestinations: rootDestinations, paths: paths
        ) else { preconditionFailure("A Core navigation layer requires its primary stack") }
        self.init(style: style, layer: layer, lifetime: lifetime)
    }

    /// 接收已通过初始化校验的模态层，不重复构造栈状态。
    init(
        style: NavigationPresentationStyle,
        layer: NavigationLayer<Scope, Destination, AlertRoute>,
        lifetime: NavigationPresentationLifetime = NavigationPresentationLifetime()
    ) {
        guard case .presentation = layer.id else {
            preconditionFailure("A presentation node requires a presentation layer")
        }
        self.style = style
        self.layer = layer
        self.lifetime = lifetime
    }

    /// 从这个模态直接打开的子模态。关闭当前模态时，子模态及其继续打开的模态也会关闭。
    var presentation: NavigationPresentationNode? {
        layer.presentation
    }

    /// 默认 primary 栈中已经 push 的页面，供只读查询。
    /// 多 Tab 模态应通过 NavigationPresentationContext 的 context(for:) 访问各 Tab 的栈。
    var path: [Destination] {
        layer.stacks[.primary]?.path ?? []
    }

    /// 直接子模态使用 sheet 展示时返回它，否则返回 nil。
    var sheet: NavigationPresentationNode? {
        presentation?.style == .sheet ? presentation : nil
    }

    /// 直接子模态使用全屏方式展示时返回它，否则返回 nil。
    var fullScreen: NavigationPresentationNode? {
        presentation?.style == .fullScreen ? presentation : nil
    }

    /// 沿着子模态逐层查找，返回最上面的一层；没有子模态时返回当前节点。
    /// 结果来自导航数据，界面可能还在播放展示或关闭动画。
    var frontmostPresentationNode: NavigationPresentationNode {
        presentation?.frontmostPresentationNode ?? self
    }

    var descendantsIncludingSelf: [NavigationPresentationNode] {
        [self] + (presentation?.descendantsIncludingSelf ?? [])
    }
}
