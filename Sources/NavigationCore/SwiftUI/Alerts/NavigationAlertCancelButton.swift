import Foundation

/// 原生提示的唯一取消入口；不参与普通按钮集合的 Action 去重。
public struct NavigationAlertCancelButton<Action: Hashable> {
    public let title: LocalizedStringResource
    public let action: Action

    public init(_ title: LocalizedStringResource, action: Action) {
        self.title = title
        self.action = action
    }
}
