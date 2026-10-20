/// 描述一次对 App 根层导航栈的操作，例如切换 Tab 或打开某个页面。
///
/// App 先把 Deep Link 等输入解析成请求，再交给 Router.submit 处理确认、模态关闭和跳转。
/// scope 指根层的某个 Tab；模态内的 push/pop 直接使用该模态的 NavigationContext。
/// Hashable 用于识别重复请求，避免相同请求反复生成新的确认提示。
public enum NavigationRequest<Scope: Hashable, Destination: NavigationDestination>: Hashable {
    /// 切换到指定根 Tab，保留所有栈的根页面和 push 路径。
    case selectScope(Scope)
    /// 切换到指定根 Tab，更新或清除它的根页面路由数据，并清空它的 push 路径。
    case setRoot(Destination?, on: Scope)
    /// 切换到指定根 Tab，用新列表替换它的 push 路径，保留根页面路由数据。
    case replacePath([Destination], on: Scope)
    /// 切换到指定根 Tab，在它已有的 push 路径末尾追加一个页面。
    case push(Destination, on: Scope)
}

extension NavigationRequest {
    var hasValidDestinations: Bool {
        switch self {
        case .selectScope: true
        case let .setRoot(destination, _): destination?.supportsNavigationEntry(.stackRoot) != false
        case let .replacePath(path, _): path.allSatisfy { $0.supportsNavigationEntry(.push) }
        case let .push(destination, _): destination.supportsNavigationEntry(.push)
        }
    }
}
