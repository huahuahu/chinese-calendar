import Foundation

/// 层开始展示的页面，独立于各栈的 root/path；内部导航不改变它。
public enum NavigationLayerRoute<Destination: NavigationDestination>: Hashable {
    case root(destination: Destination)
    case presentation(id: UUID, destination: Destination)

    public var destination: Destination {
        switch self {
        case let .root(destination), let .presentation(_, destination): destination
        }
    }

    /// Context 缓存、关闭与查找只比较身份，不比较页面数据。
    public var id: NavigationLayerID {
        switch self {
        case .root: .root
        case let .presentation(id, _): .presentation(id)
        }
    }
}

extension NavigationLayerRoute: Codable where Destination: Codable {}
