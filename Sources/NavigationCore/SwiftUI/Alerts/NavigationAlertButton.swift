import Foundation

/// 普通／危险操作按钮；取消按钮使用独立类型，不在此处指定取消样式。
public struct NavigationAlertButton<Action: Hashable> {
    public enum Role { case standard, destructive }
    public let title: LocalizedStringResource
    public let action: Action
    public let role: Role

    public init(_ title: LocalizedStringResource, action: Action, role: Role = .standard) {
        self.title = title
        self.action = action
        self.role = role
    }
}
