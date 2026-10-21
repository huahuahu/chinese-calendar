import SwiftUI

/// 显示一个模态，并为它继续打开的子模态和 alert 安装唯一的呈现宿主。
/// 使用该模态自己的 NavigationPresentationContext，继承根 navigationHost 的页面构建配置；
/// Core 自动提供 primary 栈，或由声明 providesNavigationContainer 的页面自行组织各栈。
public struct NavigationPresentationNodeView<
    Scope: NavigationScope,
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
