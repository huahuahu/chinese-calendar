/// 描述一次对根层导航栈的操作，例如切换栈或打开某个页面。
///
/// App 先把 Deep Link 等输入解析成请求，再交给 Router.submit 处理确认、模态关闭和跳转。
/// primary 和命名栈使用同一种目标身份；模态内的操作使用该层的 Context。
/// Hashable 用于识别重复请求，避免相同请求反复生成新的确认提示。
public enum NavigationRequest<Scope: Hashable, Destination: NavigationDestination>: Hashable {
    /// 切换到指定根栈，保留所有栈的根页面和 push 路径。
    case selectStack(NavigationStackID<Scope>)
    /// 切换到指定根栈并替换根页面，清空路径。只有外部容器可以清除显式根页面。
    case setRoot(Destination?, on: NavigationStackID<Scope>)
    /// 切换到指定根栈，用新列表替换路径，保留根页面。
    case replacePath([Destination], on: NavigationStackID<Scope>)
    /// 切换到指定根栈，在已有路径末尾追加页面。
    case push(Destination, on: NavigationStackID<Scope>)
}

public extension NavigationRequest {
    /// 命名栈的便利入口，例如根 Tab。
    static func selectScope(_ scope: Scope) -> Self {
        .selectStack(.scope(scope))
    }

    static func setRoot(_ destination: Destination?, on scope: Scope) -> Self {
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
