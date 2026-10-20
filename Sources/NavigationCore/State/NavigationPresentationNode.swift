import Foundation
import Observation

/// 记录一个已经加入导航状态的模态：展示什么页面、怎样展示，以及它内部的导航状态。
///
/// 父层通过 presentation 持有这个节点。节点的 layer 保存内部各栈的路径和子模态，
/// 因此一个模态可以继续打开另一个模态。每次通过 present 打开页面都会生成新的节点 ID。
/// 页面可读取这些属性；修改路径或打开、关闭模态时，使用对应的 Context。
@MainActor
@Observable
public final class NavigationPresentationNode<
    Scope: Hashable,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
>: Identifiable {
    /// 这一次打开模态的 ID，用于 SwiftUI 展示、指定关闭目标和保存快照。
    public var id: UUID {
        guard case let .presentation(id) = layer.id else {
            preconditionFailure("A presentation node requires a presentation layer")
        }
        return id
    }

    /// 构建模态初始页面所需的路由数据；后续 push 的页面保存在栈的 path 中。
    public var destination: Destination {
        layer.route.destination
    }

    /// 这个模态使用 sheet 还是全屏方式展示。
    public let style: NavigationPresentationStyle
    let layer: NavigationLayer<Scope, Destination, AlertRoute>

    init(
        id: UUID = UUID(), destination: Destination, style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:]
    ) {
        self.style = style
        layer = NavigationLayer(
            route: .presentation(id: id, destination: destination), selectedStack: initialStack,
            roots: destination.providesNavigationContainer ? rootDestinations : [.primary: destination]
        )
    }

    /// 从这个模态直接打开的子模态。关闭当前模态时，子模态及其继续打开的模态也会关闭。
    public var presentation: NavigationPresentationNode? {
        layer.presentation
    }

    /// 默认 primary 栈中已经 push 的页面，供只读查询。
    /// 多 Tab 模态应通过呈现 Context 的 context(for:) 访问各 Tab 的栈。
    public var path: [Destination] {
        layer.stacks[.primary]?.path ?? []
    }

    /// 直接子模态使用 sheet 展示时返回它，否则返回 nil。
    public var sheet: NavigationPresentationNode? {
        presentation?.style == .sheet ? presentation : nil
    }

    /// 直接子模态使用全屏方式展示时返回它，否则返回 nil。
    public var fullScreen: NavigationPresentationNode? {
        presentation?.style == .fullScreen ? presentation : nil
    }

    /// 沿着子模态逐层查找，返回最上面的一层；没有子模态时返回当前节点。
    /// 结果来自导航数据，界面可能还在播放展示或关闭动画。
    public var frontmostPresentationNode: NavigationPresentationNode {
        presentation?.frontmostPresentationNode ?? self
    }

    var descendantsIncludingSelf: [NavigationPresentationNode] {
        [self] + (presentation?.descendantsIncludingSelf ?? [])
    }
}
