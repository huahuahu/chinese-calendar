import SwiftUI

/// 构建根界面或模态入口：页面自带容器时直接构建，否则用 NavigationScopeView 提供 primary 栈。
/// 本视图不处理模态和 alert；它们由所在层的 navigationPresentations 宿主统一展示。
struct NavigationLayerContent<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: View {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    var body: some View {
        if context.layer != nil {
            let destination = context.destination
            if let configuration {
                if destination.providesNavigationContainer {
                    configuration.page(for: destination)
                } else {
                    NavigationScopeView(stack: context.selectedStack, presentation: context)
                }
            } else {
                missingNavigationConfiguration()
            }
        }
    }
}

func missingNavigationRoot() -> EmptyView {
    preconditionFailure("A routed navigation stack requires a root Destination.")
}
