import SwiftUI

/// 根层与模态层共用的容器选择；不挂载呈现宿主，也不为 push 页面创建容器。
struct NavigationLayerContent<
    Scope: Hashable, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: View {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    @Environment(\.[navigation: NavigationConfigurationKey<Scope, Destination, AlertRoute>()]) private var configuration

    var body: some View {
        if let destination = context.destination {
            if let configuration {
                if destination.providesNavigationContainer {
                    configuration.page(for: destination)
                } else {
                    switch destination.navigationContainer {
                    case .stack:
                        NavigationScopeView(stack: context.selectedStack, presentation: context)
                    case .twoColumn, .threeColumn:
                        unsupportedNavigationContainer()
                    }
                }
            } else {
                missingNavigationConfiguration()
            }
        }
    }
}

private func unsupportedNavigationContainer() -> EmptyView {
    preconditionFailure("Split navigation containers are not implemented; see issue #146.")
}

func missingNavigationRoot() -> EmptyView {
    preconditionFailure("A routed navigation stack requires a root Destination.")
}
