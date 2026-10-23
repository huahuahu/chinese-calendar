import Foundation

/// 保存一条等待用户确认的导航请求，以及这一次确认提示的 ID。
///
/// 创建提示时保留当前路径和模态。相同待确认请求复用提示，换成不同请求时生成新的 ID。
/// 确认和取消按钮都携带提示 ID，避免用户点击旧提示时误操作新请求。
public struct NavigationConfirmation<Scope: NavigationScope, Destination: NavigationDestination>: Identifiable {
    /// 这次确认提示的 ID，用来匹配确认或取消操作。它与页面、模态的 ID 分开。
    public let id: NavigationConfirmationID
    /// 用户确认后，需要交给 Router 执行的导航请求。
    public let request: NavigationRequest<Scope, Destination>

    /// 为请求创建新的确认提示 ID。是否复用已有提示，由 Router.submit 判断。
    public init(request: NavigationRequest<Scope, Destination>) {
        id = NavigationConfirmationID()
        self.request = request
    }
}
