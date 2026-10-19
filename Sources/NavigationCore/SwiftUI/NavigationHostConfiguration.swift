import SwiftUI

/// 一棵导航树的页面构建与呈现策略，只由 View 宿主持有，不属于 Router 或操作 Context。
/// 使用保存业务依赖的值类型与方法实现；不要把根页面的临时选择或回调捕获为全树上下文。
@MainActor
public protocol NavigationHostConfiguration<Scope, Destination, AlertRoute> {
    associatedtype Scope: Hashable
    associatedtype Destination: Hashable
    associatedtype AlertRoute: NavigationAlertRoute
    associatedtype DestinationContent: View
    associatedtype PresentedContent: View

    /// 根层各栈中的 push 页面，继承所在栈的业务环境。
    @ViewBuilder func destination(for destination: Destination) -> DestinationContent

    /// 模态初始页面及其内部各栈的 push 页面；默认复用普通页面映射。
    @ViewBuilder func presentedDestination(for destination: Destination) -> PresentedContent

    /// 普通模态提供 primary 栈；自带多个栈的容器返回 false。
    func providesNavigationStack(for destination: Destination) -> Bool
    func confirmationContent(for request: NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent?
    func alertContent(for route: AlertRoute) -> NavigationAlertContent<AlertRoute.Action>?

    /// 系统 alert 实际关闭后调用，异步动作完成前不推进等待中的导航。
    func handleAlertAction(
        _ route: AlertRoute,
        action: AlertRoute.Action,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) async

    /// 任意层子模态实际关闭并由 Core 处理状态后调用，只用于业务清理。
    func presentationDidDismiss()
}

public extension NavigationHostConfiguration {
    func presentedDestination(for destination: Destination) -> some View {
        self.destination(for: destination)
    }

    func providesNavigationStack(for destination: Destination) -> Bool {
        true
    }

    func confirmationContent(
        for request: NavigationRequest<Scope, Destination>
    ) -> NavigationConfirmationContent? {
        nil
    }

    func alertContent(for route: AlertRoute) -> NavigationAlertContent<AlertRoute.Action>? {
        nil
    }

    func handleAlertAction(
        _ route: AlertRoute,
        action: AlertRoute.Action,
        presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) async {}
    func presentationDidDismiss() {}
}
