import SwiftUI

/// 为指定栈创建 NavigationStack，绑定它的 path，并根据路由数据构建 push 页面。
///
/// App 根 Tab、普通模态和模态内部的 Tab 都可以使用这个容器。
/// 根页面及所有 push 页面都会得到本栈的 NavigationContext，以及记录了发起栈的呈现 Context。
/// 页面内容直接使用这些环境对象，不必再次包一层 NavigationStack。
/// NavigationLink(value:) 和 context.push 都会更新同一份路径。
/// 模态展示由所属层的 navigationPresentations 统一处理，各 Tab 无需分别挂载。
public struct NavigationScopeView<
    Scope: Hashable,
    Destination: Hashable,
    AlertRoute: NavigationAlertRoute,
    Root: View,
    DestinationContent: View
>: View {
    @Bindable private var context: NavigationContext<Scope, Destination>
    private let presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    private let root: () -> Root
    private let destinationContent: (Destination) -> DestinationContent

    /// - Parameters:
    ///   - context: 要使用的栈 Context，从 Router 或本层呈现 Context 获取。
    ///   - root: 构建栈的根页面，它不计入 path。根页面由路由数据决定时，在这里读取该数据。
    ///   - destinationContent: 根据 path 中的路由数据构建 push 页面，容器会统一注册 navigationDestination。
    public init(
        context: NavigationContext<Scope, Destination>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root,
        @ViewBuilder destinationContent: @escaping (Destination) -> DestinationContent
    ) {
        self.context = context
        self.presentation = presentation
        self.root = root
        self.destinationContent = destinationContent
    }

    public var body: some View {
        NavigationStack(path: $context.path) {
            root()
                .navigationDestination(for: Destination.self, destination: destinationContent)
        }
        .environment(context)
        .environment(presentation.scoped(to: context.id))
    }
}
