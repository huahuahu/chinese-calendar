// swiftformat:disable modifierOrder

/// 描述页面的路由数据，以及作为根界面或模态入口时是否自带导航容器。
/// View 由宿主配置构建，页面的选择和查询等业务状态由 App 管理。
nonisolated public protocol NavigationDestination: Hashable, SendableMetatype {
    /// true 表示页面自行组织 TabView／SplitView 等容器及其中的栈，Core 不在外面重复包栈；
    /// false 表示由 Core 提供 primary NavigationStack。根层与模态层使用同一规则。
    /// 页面被 push 到已有栈时，不根据此属性再创建导航容器。
    var providesNavigationContainer: Bool { get }
}

public extension NavigationDestination {
    nonisolated var providesNavigationContainer: Bool {
        false
    }
}
