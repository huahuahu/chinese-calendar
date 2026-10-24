import SwiftUI

/// 退出动画期间保留本次节点及路由参数，配置始终继承根宿主。
struct NavigationPresentationNodeView<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: View {
    let node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>

    var body: some View {
        NavigationLayerContent(context: context)
            .navigationPresentations(context: context)
    }
}
