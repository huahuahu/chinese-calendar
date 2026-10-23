import SwiftUI

/// 强持本次节点到系统关闭完成，使退出动画仍有可渲染的栈与业务配置。
struct NavigationPresentationNodeView<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: View {
    let node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    let record: NavigationPresentationRenderRecord<Scope, Destination, AlertRoute>

    var body: some View {
        NavigationLayerContent(context: context)
            .navigationPresentations(context: context)
            .background {
                if let mount = record.modalMount {
                    NavigationModalLifecycle(mount: mount, lifetime: node.lifetime)
                        .frame(width: 0, height: 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}
