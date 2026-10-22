import Observation

/// 保存一个导航栈的栈底页面 Destination，以及之后 push 的页面列表。
/// 栈 Context 直接读写这个对象；它本身不处理模态展示或关闭。
@MainActor
@Observable
final class NavigationStackState<Destination: NavigationDestination> {
    var rootDestination: Destination
    /// 只保存根页面之上的 push 页面；空数组表示停留在栈根。
    var path: [Destination]

    init(rootDestination: Destination, path: [Destination] = []) {
        self.rootDestination = rootDestination
        self.path = path
    }
}
