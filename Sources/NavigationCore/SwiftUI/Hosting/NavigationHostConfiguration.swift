import SwiftUI

/// 一棵导航树的页面构建与呈现策略，只由 View 宿主持有，不属于 Router 或操作 Context。
/// 使用保存业务依赖的值类型与方法实现；各页的选择、数据会话和回调仍由对应页面提供，
/// 不能把根页面的这类临时状态固定到配置中，再交给所有模态和栈使用。
@MainActor
public protocol NavigationHostConfiguration<Scope, Destination, AlertRoute> {
    associatedtype Scope: NavigationScope
    associatedtype Destination: NavigationDestination
    associatedtype AlertRoute: NavigationAlertRoute
    associatedtype DestinationContent: View

    /// 构建根界面、模态入口、由 Destination 指定的栈底页面，以及所有 push 页面。
    /// 宿主为页面注入所在层的 NavigationPresentationContext；栈内页面还会得到所属栈的 NavigationContext。
    @ViewBuilder func destination(for destination: Destination) -> DestinationContent

    func confirmationContent(for request: NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent?

    /// 根据业务路由提供 alert 文案、按钮及对应的异步操作，由 NavigationAlertPresenter 显示。
    /// 动作只在系统 alert 实际关闭后执行；异步动作完成前不推进等待中的导航。
    func alert(
        for route: AlertRoute,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) -> NavigationAlertDefinition?
}

public extension NavigationHostConfiguration {
    func confirmationContent(
        for request: NavigationRequest<Scope, Destination>
    ) -> NavigationConfirmationContent? {
        nil
    }

    func alert(
        for route: AlertRoute,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) -> NavigationAlertDefinition? {
        nil
    }
}

extension NavigationHostConfiguration {
    /// 将不同配置返回的页面包装为 AnyView，供持有 any NavigationHostConfiguration 的代码统一调用。
    func page(for destination: Destination) -> AnyView {
        AnyView(self.destination(for: destination))
    }
}
