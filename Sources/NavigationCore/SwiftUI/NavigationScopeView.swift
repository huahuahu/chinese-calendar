import SwiftUI

/// 为指定栈创建 NavigationStack，绑定它的 path，并根据路由数据构建 push 页面。
///
/// 普通根界面、Tab 中的栈、SplitView 的详情栈和模态内部的栈都可以使用这个宿主。
/// 栈底页面及所有 push 页面都会得到本栈的 NavigationContext。
/// 默认注入记录了发起栈的呈现 Context；关闭选中栈限制时，注入本层不限制发起栈的呈现 Context。
/// 页面内容直接使用这些环境对象，不必再次包一层 NavigationStack。
/// NavigationLink(value:) 和 context.push 都会更新同一份路径。
/// 模态展示由所属层的 navigationPresentations 统一处理，各 Tab 无需分别挂载。
public struct NavigationScopeView<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute,
    Root: View
>: View {
    @Bindable private var context: NavigationContext<Scope, Destination>
    private let presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    private let restrictsPresentationToSelectedStack: Bool
    private let root: (() -> Root)?
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    /// - Parameters:
    ///   - context: 要使用的栈 Context，从 Router 或本层呈现 Context 获取。
    ///   - restrictsPresentationToSelectedStack: Tab 保持默认值；可同时交互的并列栏目设为 false。
    ///   - root: 覆盖栈底内容，供 Preview 等需要注入临时内容的宿主使用；内容不计入 path。
    ///     栈仍必须声明 rootDestination，此闭包不会修改它。正式页面使用不带 root 的初始化方法，
    ///     由 navigationHost 配置统一构建根页面，包括 SplitView 的详情和空态。
    /// 所在导航树必须通过 navigationHost 提供配置；本栈独立注册 navigationDestination。
    public init(
        context: NavigationContext<Scope, Destination>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        restrictsPresentationToSelectedStack: Bool = true,
        @ViewBuilder root: @escaping () -> Root
    ) {
        self.context = context
        self.presentation = presentation
        self.restrictsPresentationToSelectedStack = restrictsPresentationToSelectedStack
        self.root = root
    }

    /// 从 presentation 所属层获取指定栈，并用 root 闭包构建栈底内容。
    /// 后续 push 页面仍使用 navigationHost 配置构建，无需在这里重复注册。
    public init(
        stack: NavigationStackID<Scope>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        restrictsPresentationToSelectedStack: Bool = true,
        @ViewBuilder root: @escaping () -> Root
    ) {
        self.init(
            context: presentation.context(for: stack), presentation: presentation,
            restrictsPresentationToSelectedStack: restrictsPresentationToSelectedStack, root: root
        )
    }

    public var body: some View {
        if let configuration {
            NavigationStack(path: $context.path) {
                rootContent
                    .navigationDestination(for: Destination.self) { destination in
                        configuration.page(for: destination)
                            // SplitView 折叠时，目标页面也必须显式绑定声明它的栈上下文。
                            .environment(context)
                            .environment(stackPresentation)
                    }
            }
            .environment(context)
            .environment(stackPresentation)
        } else {
            missingNavigationConfiguration()
        }
    }

    private var stackPresentation: NavigationPresentationContext<Scope, Destination, AlertRoute> {
        restrictsPresentationToSelectedStack ? presentation.scoped(to: context.id) : presentation.unscoped()
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

    /// 自动读取指定栈的 rootDestination，并交给 navigationHost 配置构建栈底页面。
    /// 栈必须先声明根再获取 Context；未声明栈的 Context 无效，不会隐式创建栈。
    public init(
        stack: NavigationStackID<Scope>,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        restrictsPresentationToSelectedStack: Bool = true
    ) where Root == EmptyView {
        context = presentation.context(for: stack)
        self.presentation = presentation
        self.restrictsPresentationToSelectedStack = restrictsPresentationToSelectedStack
        root = nil
    }
}
