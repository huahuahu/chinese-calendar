import SwiftUI

public extension View {
    /// 在导航树的根 View 配置一次页面映射与策略；各栈及递归模态自动继承。
    /// 独立导航树应分别挂载此宿主，即使它们使用相同路由类型，也可以提供不同配置。
    func navigationHost<Configuration: NavigationHostConfiguration>(
        context: NavigationPresentationContext<
            Configuration.Scope,
            Configuration.Destination,
            Configuration.AlertRoute
        >,
        configuration: Configuration
    ) -> some View {
        navigationPresentations(context: context)
            .environment(
                \.[navigation: NavigationConfigurationKey<
                    Configuration.Scope,
                    Configuration.Destination,
                    Configuration.AlertRoute
                >()],
                configuration
            )
    }
}
