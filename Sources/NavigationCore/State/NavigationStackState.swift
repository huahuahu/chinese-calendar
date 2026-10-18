import Observation

/// 保存一个导航栈的根页面路由数据和 push 路径。
/// 栈 Context 直接读写这个对象；它本身不处理模态展示或关闭。
@MainActor
@Observable
final class NavigationStackState<Destination: Hashable> {
    var rootDestination: Destination?
    /// nil 表示还没有记录路径；[] 表示已记录路径，但没有 push 页面。
    /// 保存快照时保留这个区别，避免仅获取 Context 就增加一条空路径记录。
    var path: [Destination]?

    init(rootDestination: Destination? = nil, path: [Destination]? = nil) {
        self.rootDestination = rootDestination
        self.path = path
    }
}
