import Foundation

/// 记录构建 App 根界面或打开一个模态时使用的 Destination。
/// 例如 present(.tabs) 创建的层记录 .tabs，各 Tab 的栈底页面和 push 路径另存于栈状态。
/// 切换栈、替换栈底或 push/pop 都不会改变这里记录的 Destination。
enum NavigationLayerRoute<Destination: NavigationDestination>: Hashable {
    case root(destination: Destination)
    case presentation(id: NavigationPresentationID, destination: Destination)

    var destination: Destination {
        switch self {
        case let .root(destination), let .presentation(_, destination): destination
        }
    }

    /// 用于查找层和缓存 Context 的 ID，不包含 Destination。
    /// 判断 Context 是否有效时还需检查原层对象，不能仅比较 ID。
    var id: NavigationLayerID {
        switch self {
        case .root: .root
        case let .presentation(id, _): .presentation(id)
        }
    }
}
