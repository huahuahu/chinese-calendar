import SwiftUI

/// 每层唯一的物理宿主；请求记录随其生命周期释放，配置不进入 Router。
private struct NavigationPresentationHost<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration
    @State private var endpoint = NavigationPresentationEndpoint<Scope, Destination, AlertRoute>()

    func body(content: Content) -> some View {
        endpoint.attach(context: context, configuration: configuration)
        let sheetMount = mount(for: .sheet)
        let fullScreenMount = mount(for: .fullScreen)
        return content
            .sheet(
                item: binding(for: .sheet), onDismiss: { sheetMount?.didDismiss() },
                content: { node in presentation(node) }
            )
            .fullScreenCover(
                item: binding(for: .fullScreen), onDismiss: { fullScreenMount?.didDismiss() },
                content: { node in presentation(node) }
            )
            .modifier(NavigationAlertHost(
                context: context,
                alertDefinition: { node in
                    let configuration = endpoint.record(for: node.lifetime)?.configuration ?? configuration
                    return configuration?.alert(for: node.destination, presentation: context)
                },
                renderLifetime: { endpoint.record(for: $0.lifetime) },
                confirmationContent: { configuration?.confirmationContent(for: $0) }
            ))
            .background {
                NavigationHostLifetime { endpoint.detach() }
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .environment(context)
    }

    @ViewBuilder
    private func presentation(_ node: NavigationPresentationNode<Scope, Destination, AlertRoute>) -> some View {
        if let childContext = context.context(for: node) {
            if let record = endpoint.record(for: node.lifetime), let configuration = record.configuration {
                NavigationPresentationNodeView(node: node, context: childContext, record: record)
                    .environment(
                        \.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()],
                        configuration
                    )
            }
        }
    }

    private func mount(for style: NavigationPresentationStyle) -> NavigationModalMount? {
        let node = context.layer?.dismissingPresentation ?? context.presentedNode
        guard let node, node.style == style else { return nil }
        return endpoint.record(for: node.lifetime)?.modalMount
    }

    private func binding(
        for style: NavigationPresentationStyle
    ) -> Binding<NavigationPresentationNode<Scope, Destination, AlertRoute>?> {
        let node = context.presentedNode
        return Binding(
            get: { context.presentedNode?.style == style ? context.presentedNode : nil },
            set: { value in
                if value == nil, let node, node.style == style { context.dismissPresented(id: node.id) }
            }
        )
    }
}

extension View {
    /// 仅由根宿主和递归模态调用，业务内容不重复挂载本层呈现宿主。
    func navigationPresentations(
        context: NavigationPresentationContext<
            some NavigationScope, some NavigationDestination, some NavigationAlertRoute
        >
    ) -> some View {
        modifier(NavigationPresentationHost(context: context))
    }
}
