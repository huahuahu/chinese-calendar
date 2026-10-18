import Foundation

/// 根据业务路由生成原生提示的文案和按钮。这里的按钮只描述数据，不执行副作用。
public struct NavigationAlertContent<Action: Hashable> {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource
    public let buttons: [NavigationAlertButton<Action>]

    public init(
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        buttons: [NavigationAlertButton<Action>]
    ) {
        precondition(!buttons.isEmpty, "An alert requires at least one action")
        precondition(Set(buttons.map(\.action)).count == buttons.count, "Alert actions must be unique")
        precondition(buttons.filter { $0.role == .cancel }.count <= 1, "An alert supports one cancel action")
        self.title = title
        self.message = message
        self.buttons = buttons
    }
}

public struct NavigationAlertButton<Action: Hashable> {
    public enum Role { case standard, cancel, destructive }
    public let title: LocalizedStringResource
    public let action: Action
    public let role: Role

    public init(_ title: LocalizedStringResource, action: Action, role: Role = .standard) {
        self.title = title
        self.action = action
        self.role = role
    }
}
