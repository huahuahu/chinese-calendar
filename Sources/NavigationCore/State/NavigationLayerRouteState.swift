import Observation

/// 导航层及其 NavigationPresentationContext 共享的入口记录。
///
/// 使用引用类型，让 NavigationLayer、普通 Context 和 scoped Context 共用同一份路由，
/// 避免各自保存值副本后再逐一同步。根快照恢复更新这份记录时，
/// @Observable 会通知读取过 route／destination 的页面。
///
/// Context 强持有这份轻量记录，但仍弱引用 Router 和所属层；记录本身不引用它们或导航栈。
/// 因此层释放后，Context 仍能读取最后的入口，也不会延长整棵导航树的生命周期。
/// 路由可读不代表 Context 仍有效，导航操作和页面渲染继续单独检查 isActive。
/// 恢复出的同 ID 模态创建新记录，旧 Context 不会跟随新层的入口变化。
@MainActor
@Observable
final class NavigationLayerRouteState<Destination: NavigationDestination> {
    /// 层入口可随根快照恢复更新；push/pop、切换栈和替换栈底页面不会改变它。
    var route: NavigationLayerRoute<Destination>

    init(route: NavigationLayerRoute<Destination>) {
        self.route = route
    }
}
