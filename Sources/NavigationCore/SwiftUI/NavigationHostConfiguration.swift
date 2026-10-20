import SwiftUI

/// 一棵导航树的页面构建与呈现策略，只由 View 宿主持有，不属于 Router 或操作 Context。
/// 使用保存业务依赖的值类型与方法实现；不要把根页面的临时选择或回调捕获为全树上下文。
@MainActor
public protocol NavigationHostConfiguration<Scope, Destination, AlertRoute> {
    associatedtype Scope: Hashable
    associatedtype Destination: NavigationDestination
    associatedtype AlertRoute: NavigationAlertRoute
    associatedtype DestinationContent: View

    /// 所有栈的 push 页面与模态初始页面，统一继承所在作用域的环境。
    @ViewBuilder func destination(for destination: Destination) -> DestinationContent

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

extension NavigationHostConfiguration {
    /// 在协议存在类型的调用边界擦除页面类型，不增加额外的 View 宿主。
    func page(for destination: Destination) -> AnyView {
        AnyView(self.destination(for: destination))
    }
}
