/// 描述一次对根层导航栈的操作，例如切换栈或打开某个页面。
///
/// App 先把 Deep Link 等输入解析成请求，再交给 Router.submit 处理确认、模态关闭和跳转。
/// primary 和命名栈使用同一种目标身份；模态内的操作使用该层的 Context。
/// Hashable 用于识别重复请求，避免相同请求反复生成新的确认提示。
public enum NavigationRequest<Scope: NavigationScope, Destination: NavigationDestination>: Hashable {
    /// 选中 App 根层中的指定栈，保留所有栈的栈底页面和 push 路径。
    case selectStack(NavigationStackID<Scope>)
    /// 选中 App 根层中的指定栈，替换其栈底页面并清空 push 路径。
    /// 不改变构建整个根界面的 Destination；空详情也使用明确的页面路由。
    case setRoot(Destination, on: NavigationStackID<Scope>)
    /// 选中 App 根层中的指定栈，用新列表替换 push 路径，保留栈底页面。
    case replacePath([Destination], on: NavigationStackID<Scope>)
    /// 选中 App 根层中的指定栈，在已有 push 路径末尾追加页面。
    case push(Destination, on: NavigationStackID<Scope>)
}

public extension NavigationRequest {
    /// 创建选中根层命名栈的请求，等价于 .selectStack(.scope(scope))。
    static func selectScope(_ scope: Scope) -> Self {
        .selectStack(.scope(scope))
    }

    static func setRoot(_ destination: Destination, on scope: Scope) -> Self {
        .setRoot(destination, on: .scope(scope))
    }

    static func replacePath(_ path: [Destination], on scope: Scope) -> Self {
        .replacePath(path, on: .scope(scope))
    }

    static func push(_ destination: Destination, on scope: Scope) -> Self {
        .push(destination, on: .scope(scope))
    }
}

extension NavigationRequest {
    var stack: NavigationStackID<Scope> {
        switch self {
        case let .selectStack(stack), let .setRoot(_, stack), let .replacePath(_, stack), let .push(_, stack): stack
        }
    }
}
