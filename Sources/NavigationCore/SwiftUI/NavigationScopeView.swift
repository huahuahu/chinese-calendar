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
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute,
    Root: View
>: View {
    @Bindable private var context: NavigationContext<Scope, Destination>
    private let presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    private let root: (() -> Root)?
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    /// - Parameters:
    ///   - context: 要使用的栈 Context，从 Router 或本层呈现 Context 获取。
    ///   - root: 构建栈的根页面，它不计入 path。根页面由路由数据决定时，在这里读取该数据。
    /// 所在导航树必须通过 navigationHost 提供配置；本栈独立注册 navigationDestination。
    public init(
        context: NavigationContext<Scope, Destination>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root
    ) {
        self.context = context
        self.presentation = presentation
        self.root = root
    }

    /// 用本层的栈身份创建容器，根页面无需重复提供后续页面的构建规则。
    public init(
        stack: NavigationStackID<Scope>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        @ViewBuilder root: @escaping () -> Root
    ) {
        self.init(context: presentation.context(for: stack), presentation: presentation, root: root)
    }

    public var body: some View {
        if let configuration {
            NavigationStack(path: $context.path) {
                rootContent
                    .navigationDestination(for: Destination.self) { destination in
                        configuration.page(for: destination)
                    }
            }
            .environment(context)
            .environment(presentation.scoped(to: context.id))
        } else {
            missingNavigationConfiguration()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if let root {
            root()
        } else if let destination = context.rootDestination, let configuration {
            configuration.page(for: destination)
        } else if context.isActive {
            missingNavigationRoot()
        }
    }

    /// 生产页面从栈状态读取根 Destination，统一交给宿主配置构建。
    public init(
        stack: NavigationStackID<Scope>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) where Root == EmptyView {
        context = presentation.context(for: stack)
        self.presentation = presentation
        root = nil
    }
}
