import SwiftUI

/// 根与递归模态共用根配置，将原生关闭回调交给本次请求。
private struct NavigationPresentationHost<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    func body(content: Content) -> some View {
        let sheet = node(for: .sheet)
        let fullScreen = node(for: .fullScreen)
        return content
            .sheet(
                item: binding(for: .sheet), onDismiss: { didDismiss(sheet) },
                content: { node in presentation(node) }
            )
            .fullScreenCover(
                item: binding(for: .fullScreen), onDismiss: { didDismiss(fullScreen) },
                content: { node in presentation(node) }
            )
            .modifier(NavigationAlertHost(
                context: context,
                alertDefinition: { configuration?.alert(for: $0.destination, presentation: context) },
                confirmationContent: { configuration?.confirmationContent(for: $0) }
            ))
            .environment(context)
    }

    private func presentation(_ node: NavigationPresentationNode<Scope, Destination, AlertRoute>) -> some View {
        node.lifetime.claimHost()
        return Group {
            if let childContext = context.context(for: node) {
                NavigationPresentationNodeView(node: node, context: childContext)
            }
        }
    }

    private func node(
        for style: NavigationPresentationStyle
    ) -> NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        let node = context.layer?.dismissingPresentation ?? context.layer?.presentation
        return node?.style == style ? node : nil
    }

    private func didDismiss(_ node: NavigationPresentationNode<Scope, Destination, AlertRoute>?) {
        guard let node else { return }
        let completion = node.lifetime.takeOnDismiss()
        context.presentationDidDismiss(lifetime: node.lifetime)
        completion?()
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
