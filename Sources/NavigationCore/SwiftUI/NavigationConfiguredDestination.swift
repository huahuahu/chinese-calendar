import SwiftUI

/// 只在页面构建边界擦除 View 类型，页面本身继续按所在栈读取环境与状态。
struct NavigationConfiguredDestination<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute>: View {
    let configuration: (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)?
    let destination: Destination
    let isPresented: Bool

    var body: some View {
        if let configuration {
            configuration.page(for: destination, isPresented: isPresented)
        } else {
            missingNavigationConfiguration()
        }
    }
}

/// 缺少宿主属于接入错误，不能把一次有效导航静默渲染为空页面。
func missingNavigationConfiguration() -> EmptyView {
    preconditionFailure("NavigationScopeView requires an ancestor navigationHost(context:configuration:).")
}

extension NavigationHostConfiguration {
    func page(for destination: Destination, isPresented: Bool) -> AnyView {
        if isPresented {
            AnyView(presentedDestination(for: destination))
        } else {
            AnyView(self.destination(for: destination))
        }
    }
}
