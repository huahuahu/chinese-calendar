import SwiftUI

/// 为一个模态提供独立 Context、可选 primary 栈及唯一子呈现宿主。
/// 页面和策略自动继承根 navigationHost 配置；多 Tab 页面自行创建各栈。
public struct NavigationPresentationNodeView<
    Scope: Hashable,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
>: View {
    private let context: NavigationPresentationContext<Scope, Destination, AlertRoute>

    /// 独立组合时也须位于 navigationHost 的配置环境内。
    public init(
        node: NavigationPresentationNode<Scope, Destination, AlertRoute>,
        context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) {
        precondition(context.layer === node.layer)
        self.context = context
    }

    public var body: some View {
        NavigationLayerContent(context: context)
            .navigationPresentations(context: context)
    }
}
