import SwiftUI

/// 根据当前层的数据展示页面或 alert，并在系统关闭完成后通知该层。
/// App 根界面挂载一次；框架会给每个模态继续添加这个容器，支持逐层打开模态。
private struct NavigationPresentationHost<
    Scope: Hashable,
    Destination: Hashable, AlertRoute: NavigationAlertRoute
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    func body(content: Content) -> some View {
        content
            .sheet(item: binding(for: .sheet), onDismiss: didDismiss, content: { node in
                presentation(node)
            })
            .fullScreenCover(
                item: binding(for: .fullScreen),
                onDismiss: didDismiss,
                content: { node in
                    presentation(node)
                }
            )
            .modifier(NavigationAlertHost(
                context: context,
                alertContent: { configuration?.alertContent(for: $0) },
                confirmationContent: { configuration?.confirmationContent(for: $0) },
                onAction: { route, action, presentation in
                    await configuration?.handleAlertAction(route, action: action, presentation: presentation)
                }
            ))
            .environment(context)
    }

    @ViewBuilder
    private func presentation(_ node: NavigationPresentationNode<Scope, Destination, AlertRoute>) -> some View {
        if let childContext = context.context(for: node) {
            NavigationPresentationNodeView(node: node, context: childContext)
        }
    }

    private func binding(
        for style: NavigationPresentationStyle
    ) -> Binding<NavigationPresentationNode<Scope, Destination, AlertRoute>?> {
        // sheet 和 fullScreenCover 读取同一个模态，只展示与自己样式匹配的节点。
        // 记录本次绑定对应的节点 ID，防止旧关闭动画的回调误关后来打开的新模态。
        let node = context.presentedNode
        return Binding(
            get: { context.presentedNode?.style == style ? context.presentedNode : nil },
            set: { value in
                // SwiftUI 写回 nil 表示关闭；只有记录的 ID 仍匹配当前模态时才会生效。
                if value == nil, let node, node.style == style { context.dismissPresented(id: node.id) }
            }
        )
    }

    private func didDismiss() {
        // 先通知框架关闭动画已完成，让本层可以重新展示，或执行等待中的根层跳转。
        // 然后通知业务清理临时数据，业务回调无需再次通知 Router。
        context.presentationDidDismiss()
        configuration?.presentationDidDismiss()
    }
}

extension View {
    /// 仅由根宿主和递归模态调用，业务内容不重复挂载本层呈现宿主。
    func navigationPresentations(
        context: NavigationPresentationContext<some Hashable, some Hashable, some NavigationAlertRoute>
    ) -> some View {
        modifier(NavigationPresentationHost(context: context))
    }
}
