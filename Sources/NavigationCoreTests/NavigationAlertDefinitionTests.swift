import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("提示内容与动作的泛型配对")
struct NavigationAlertDefinitionTests {
    private enum Action: Hashable { case first, second }

    @Test func erasureKeepsDeduplicatedOrderRolesAndIndependentCancellation() async {
        var actions: [Action] = []
        let definition = NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "标题", message: "消息",
                firstButton: NavigationAlertButton("首项原文", action: Action.first),
                additionalButtons: [
                    NavigationAlertButton("第二项", action: .second),
                    NavigationAlertButton("首项新版", action: .first, role: .destructive)
                ],
                cancelButton: NavigationAlertCancelButton("取消", action: .first)
            )
        ) { actions.append($0) }

        #expect(actions.isEmpty)
        #expect(String(localized: definition.title) == "标题")
        #expect(String(localized: definition.message) == "消息")
        #expect(definition.buttons.map { String(localized: $0.title) } == ["取消", "首项新版", "第二项"])
        #expect(definition.buttons.map(\.isCancel) == [true, false, false])
        #expect(definition.buttons.map(\.isDestructive) == [false, true, false])
        for button in definition.buttons {
            await button.perform()
        }
        #expect(actions == [.first, .first, .second])
    }

    @Test func cancellationOnlyPreservesItsTypedAction() async {
        var actions: [Action] = []
        let definition = NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "标题", message: "消息",
                cancelButton: NavigationAlertCancelButton("关闭", action: Action.second)
            )
        ) { actions.append($0) }

        #expect(definition.buttons.count == 1)
        #expect(definition.buttons[0].isCancel)
        #expect(!definition.buttons[0].isDestructive)
        await definition.buttons[0].perform()
        #expect(actions == [.second])
    }
}
