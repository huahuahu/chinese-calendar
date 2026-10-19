import SwiftUI

/// 为一个模态提供独立 Context、可选 primary 栈及唯一子呈现宿主。
/// 页面和策略自动继承根 navigationHost 配置；多 Tab 页面自行创建各栈。
public struct NavigationPresentationNodeView<
    Scope: Hashable,
    Destination: Hashable,
    AlertRoute: NavigationAlertRoute
>: View {
    private let node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    private let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    /// 独立组合时也须位于 navigationHost 的配置环境内。
    public init(
        node: NavigationPresentationNode<Scope, Destination, AlertRoute>,
        context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) {
        self.node = node
        self.context = context
    }

    public var body: some View {
        presentationContent
            .navigationPresentations(context: context)
    }

    @ViewBuilder
    private var presentationContent: some View {
        if let configuration {
            if configuration.providesNavigationStack(for: node.destination) {
                NavigationScopeView(stack: .primary, presentation: context) {
                    NavigationConfiguredDestination(
                        configuration: configuration, destination: node.destination, isPresented: true
                    )
                }
            } else {
                NavigationConfiguredDestination(
                    configuration: configuration, destination: node.destination, isPresented: true
                )
            }
        } else {
            missingNavigationConfiguration()
        }
    }
}
