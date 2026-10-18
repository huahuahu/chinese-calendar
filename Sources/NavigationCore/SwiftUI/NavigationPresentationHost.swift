import SwiftUI

/// 根据当前层的数据展示页面或 alert，并在系统关闭完成后通知该层。
/// App 根界面挂载一次；框架会给每个模态继续添加这个容器，支持逐层打开模态。
private struct NavigationPresentationHost<
    Scope: Hashable,
    Destination: Hashable, AlertRoute: NavigationAlertRoute,
    DestinationContent: View
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    let providesNavigationStack: (Destination) -> Bool
    let confirmationContent: ((NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent)?
    let alertContent: ((AlertRoute) -> NavigationAlertContent<AlertRoute.Action>)?
    let onAlertAction: @MainActor (
        AlertRoute,
        AlertRoute.Action,
        NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) async -> Void
    let onDismiss: () -> Void
    let destinationContent: (Destination) -> DestinationContent

    func body(content: Content) -> some View {
        content
            .sheet(item: binding(for: .sheet), onDismiss: didDismiss, content: { node in
                presentation(node)
            })
            .navigationFullScreenCover(
                item: binding(for: .fullScreen),
                onDismiss: didDismiss,
                content: { node in
                    presentation(node)
                }
            )
            .modifier(NavigationAlertHost(
                context: context, alertContent: alertContent,
                confirmationContent: confirmationContent, onAction: onAlertAction
            ))
            .environment(context)
    }

    @ViewBuilder
    private func presentation(_ node: NavigationPresentationNode<Scope, Destination, AlertRoute>) -> some View {
        if let childContext = context.context(for: node) {
            NavigationPresentationNodeView(
                node: node,
                context: childContext,
                providesNavigationStack: providesNavigationStack,
                confirmationContent: confirmationContent,
                alertContent: alertContent,
                onAlertAction: onAlertAction,
                onDismiss: onDismiss,
                destinationContent: destinationContent
            )
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
        onDismiss()
    }
}

public extension View {
    /// 让这个界面容器统一处理当前层的模态展示、关闭和离开确认，并提供呈现 Context 环境。
    ///
    /// App 根界面传入 router.rootPresentation。后续每个模态由框架自动添加对应的容器。
    /// 普通页面和模态内的 Tab 容器无需重复调用，否则同一层会有多个地方负责展示模态。
    /// 所有页面都通过 destinationContent 从路由数据构建。
    /// - Parameters:
    ///   - context: 这一层的呈现 Context，用来读取和修改模态状态。
    ///   - providesNavigationStack: 是否自动为模态添加 primary 导航栈，默认 true。
    ///     模态自带多个 Tab 栈或完全不需要导航栈时返回 false；各 Tab 可以使用 NavigationScopeView。
    ///   - confirmationContent: 根据导航请求提供确认文案。省略时不显示默认提示，
    ///     业务需自行观察 context.confirmation，并使用请求 ID 确认或取消。
    ///   - alertContent: 根据业务 alert 路由提供文案和强类型按钮；使用业务 alert 时必须提供。
    ///   - onAlertAction: 系统 alert 关闭后执行业务动作，完成前不会推进等待中的导航。
    ///   - onDismiss: 任意层的子模态关闭完成后调用，供业务清理临时数据。
    ///     框架会先处理导航状态；嵌套关闭时可能多次调用，并非每次都表示根模态关闭。
    ///   - destinationContent: 根据 destination 路由数据构建页面内容。
    func navigationPresentations<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute>(
        context: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        providesNavigationStack: @escaping (Destination) -> Bool = { _ in true },
        confirmationContent: ((NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent)? = nil,
        alertContent: ((AlertRoute) -> NavigationAlertContent<AlertRoute.Action>)? = nil,
        onAlertAction: @escaping @MainActor (
            AlertRoute,
            AlertRoute.Action,
            NavigationPresentationContext<Scope, Destination, AlertRoute>
        ) async -> Void = { _, _, _ in },
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder destinationContent: @escaping (Destination) -> some View
    ) -> some View {
        modifier(NavigationPresentationHost(
            context: context,
            providesNavigationStack: providesNavigationStack,
            confirmationContent: confirmationContent,
            alertContent: alertContent,
            onAlertAction: onAlertAction,
            onDismiss: onDismiss,
            destinationContent: destinationContent
        ))
    }
}
