import Foundation

/// 记录构建 App 根界面或打开一个模态时使用的 Destination。
/// 例如 present(.tabs) 创建的层记录 .tabs，各 Tab 的栈底页面和 push 路径另存于栈状态。
/// 切换栈、替换栈底或 push/pop 都不会改变这里记录的 Destination。
public enum NavigationLayerRoute<Destination: NavigationDestination>: Hashable {
    case root(destination: Destination)
    case presentation(id: UUID, destination: Destination)

    public var destination: Destination {
        switch self {
        case let .root(destination), let .presentation(_, destination): destination
        }
    }

    /// 用于查找层和缓存 Context 的 ID，不包含 Destination。
    /// 恢复出的新模态可以沿用同一 ID；判断旧 Context 是否有效时还需检查层对象是否相同。
    public var id: NavigationLayerID {
        switch self {
        case .root: .root
        case let .presentation(id, _): .presentation(id)
        }
    }
}

extension NavigationLayerRoute: Codable where Destination: Codable {}
