import SwiftUI

/// 为一个模态构建页面、提供环境对象，并支持从它继续打开子模态。
///
/// 默认使用 primary 导航栈，模态的初始页面及其 push 页面共享这个栈。
/// 包含多个 Tab 的模态可以关闭默认栈包装，再通过本层呈现 Context 获取各 Tab 的栈。
/// 无论是否添加默认导航栈，这个容器都会通过 navigationPresentations 处理下一层模态。
/// 通常由框架自动创建，业务的 destinationContent 只需返回页面内容。
public struct NavigationPresentationNodeView<
    Scope: Hashable,
    Destination: Hashable,
    AlertRoute: NavigationAlertRoute,
    DestinationContent: View
>: View {
    private let node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    private let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    private let providesNavigationStack: (Destination) -> Bool
    private let confirmationContent: ((NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent)?
    private let alertContent: ((AlertRoute) -> NavigationAlertContent<AlertRoute.Action>)?
    private let onAlertAction: @MainActor (
        AlertRoute,
        AlertRoute.Action,
        NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) async -> Void
    private let onDismiss: () -> Void
    private let destinationContent: (Destination) -> DestinationContent

    /// 创建指定模态的页面容器。
    /// - Parameters:
    ///   - node: 要展示的模态，包含页面路由数据、ID 和展示方式。
    ///   - context: 该模态的呈现 Context，使用 router.presentationContext(for: node) 获取。
    ///   - providesNavigationStack: 是否给模态添加 primary 导航栈，后续子模态也使用这个判断闭包。
    ///   - confirmationContent: 确认提示的文案。省略时，由业务代码自行处理待确认请求。
    ///   - onDismiss: 本层或后续层的子模态关闭完成后的业务清理回调，框架会先处理导航状态。
    ///   - destinationContent: 根据路由数据构建模态初始页面，以及在其中 push 的页面。
    public init(
        node: NavigationPresentationNode<Scope, Destination, AlertRoute>,
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
        @ViewBuilder destinationContent: @escaping (Destination) -> DestinationContent
    ) {
        self.node = node
        self.context = context
        self.providesNavigationStack = providesNavigationStack
        self.confirmationContent = confirmationContent
        self.alertContent = alertContent
        self.onAlertAction = onAlertAction
        self.onDismiss = onDismiss
        self.destinationContent = destinationContent
    }

    public var body: some View {
        presentationContent
            .navigationPresentations(
                context: context,
                providesNavigationStack: providesNavigationStack,
                confirmationContent: confirmationContent,
                alertContent: alertContent,
                onAlertAction: onAlertAction,
                onDismiss: onDismiss,
                destinationContent: destinationContent
            )
    }

    @ViewBuilder
    private var presentationContent: some View {
        if providesNavigationStack(node.destination) {
            NavigationScopeView(context: context.context(for: .primary), presentation: context) {
                destinationContent(node.destination)
            } destinationContent: { destination in
                destinationContent(destination)
            }
        } else {
            // 让多 Tab 内容自己创建各栈；外面仍会提供呈现 Context 和子模态展示能力。
            destinationContent(node.destination)
        }
    }
}
