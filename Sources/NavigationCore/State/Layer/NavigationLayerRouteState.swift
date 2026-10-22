/// 导航层及其 NavigationPresentationContext 共享的不可变入口记录。
///
/// Context 强持有这份轻量记录，但仍弱引用 Router 和所属层；记录本身不引用它们或导航栈。
/// 因此层释放后，Context 仍能读取原入口，也不会延长整棵导航树的生命周期。
/// 路由可读不代表 Context 仍有效，导航操作和页面渲染继续单独检查 isActive。
@MainActor
final class NavigationLayerRouteState<Destination: NavigationDestination> {
    let route: NavigationLayerRoute<Destination>

    init(route: NavigationLayerRoute<Destination>) {
        self.route = route
    }
}
