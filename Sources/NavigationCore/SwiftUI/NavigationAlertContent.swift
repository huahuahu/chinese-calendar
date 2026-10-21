import Foundation

/// 根据业务路由生成原生提示的文案和按钮。这里的按钮只描述数据，不执行副作用。
public struct NavigationAlertContent<Action: Hashable> {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource
    /// 普通／危险按钮按 Action 首次出现的顺序排列；重复 Action 使用最后一次提供的内容。
    public let buttons: [NavigationAlertButton<Action>]
    /// 取消按钮独立于普通按钮集合，允许与普通按钮产生相同的业务 Action。
    public let cancelButton: NavigationAlertCancelButton<Action>?

    /// 必须提供首个普通／危险按钮，从构造入口保证提示非空。
    public init(
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        firstButton: NavigationAlertButton<Action>,
        additionalButtons: [NavigationAlertButton<Action>] = [],
        cancelButton: NavigationAlertCancelButton<Action>? = nil
    ) {
        var ordered = [firstButton]
        var positions = [firstButton.action: 0]
        for button in additionalButtons {
            if let index = positions[button.action] {
                ordered[index] = button
            } else {
                positions[button.action] = ordered.count
                ordered.append(button)
            }
        }
        self.title = title
        self.message = message
        buttons = ordered
        self.cancelButton = cancelButton
    }

    /// 只有取消按钮时使用此入口，不开放空提示的初始化方式。
    public init(
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        cancelButton: NavigationAlertCancelButton<Action>
    ) {
        self.title = title
        self.message = message
        buttons = []
        self.cancelButton = cancelButton
    }

    struct PresentationButton {
        let title: LocalizedStringResource
        let action: Action
        let isCancel: Bool
        let isDestructive: Bool
    }

    /// 显示与点击回传共用此顺序；取消按钮保留在原生提示的第一个位置。
    var presentationButtons: [PresentationButton] {
        let cancel = cancelButton.map {
            [PresentationButton(title: $0.title, action: $0.action, isCancel: true, isDestructive: false)]
        } ?? []
        return cancel + buttons.map {
            PresentationButton(
                title: $0.title,
                action: $0.action,
                isCancel: false,
                isDestructive: $0.role == .destructive
            )
        }
    }
}
