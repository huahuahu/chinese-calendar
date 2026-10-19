import SwiftUI

/// 按路由类型读取最近的宿主配置；默认 nil 不分配对象，也不注册进程级状态。
nonisolated struct NavigationConfigurationKey<
    Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute
>: EnvironmentKey, Hashable {
    static var defaultValue: (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)? {
        nil
    }
}

extension EnvironmentValues {
    /// KeyPath 的下标必须 Hashable，使用无状态的泛型值标识对应环境键。
    subscript<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute>(
        navigation key: NavigationConfigurationKey<Scope, Destination, AlertRoute>
    ) -> (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)? {
        get { self[NavigationConfigurationKey<Scope, Destination, AlertRoute>.self] }
        set { self[NavigationConfigurationKey<Scope, Destination, AlertRoute>.self] = newValue }
    }
}

/// 缺少宿主属于接入错误，不能把一次有效导航静默渲染为空页面。
func missingNavigationConfiguration() -> EmptyView {
    preconditionFailure("NavigationScopeView requires an ancestor navigationHost(context:configuration:).")
}
