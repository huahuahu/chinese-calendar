import SwiftUI

/// 由根层 Destination 构建 App 入口；在外部挂载一次 navigationHost 提供配置与呈现。
public struct NavigationRootView<
    Scope: Hashable, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: View {
    private let context: NavigationPresentationContext<Scope, Destination, AlertRoute>

    public init(context: NavigationPresentationContext<Scope, Destination, AlertRoute>) {
        precondition(context.id == .root)
        self.context = context
    }

    public var body: some View {
        NavigationLayerContent(context: context)
    }
}
