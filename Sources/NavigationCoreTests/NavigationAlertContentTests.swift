import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("提示按钮的构造约束与有序覆盖")
struct NavigationAlertContentTests {
    private enum Action: Hashable { case first, second, third, cancel }

    @Test func firstButtonAloneProducesANonemptyAlert() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息", firstButton: NavigationAlertButton("确定", action: Action.first)
        )
        #expect(content.buttons.map(\.action) == [.first])
        #expect(content.cancelButton == nil)
        #expect(content.presentationButtons.count == 1)
        #expect(!content.presentationButtons[0].isCancel)
    }

    @Test func laterValuesReplaceTitleAndRoleWithoutChangingFirstOccurrenceOrder() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息",
            firstButton: NavigationAlertButton("首项原文", action: Action.first),
            additionalButtons: [
                NavigationAlertButton("第二项原文", action: .second, role: .destructive),
                NavigationAlertButton("首项新版", action: .first, role: .destructive),
                NavigationAlertButton("第三项", action: .third),
                NavigationAlertButton("第二项新版", action: .second)
            ]
        )
        #expect(content.buttons.map(\.action) == [.first, .second, .third])
        #expect(content.buttons.map { String(localized: $0.title) } == ["首项新版", "第二项新版", "第三项"])
        #expect(content.buttons.map(\.role) == [.destructive, .standard, .standard])
        #expect(content.presentationButtons.map(\.action) == [.first, .second, .third])
        #expect(content.presentationButtons.map(\.isDestructive) == [true, false, false])
    }

    @Test func replacingEveryButtonWithTheSameActionStillLeavesOneButton() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息",
            firstButton: NavigationAlertButton("原文", action: Action.first),
            additionalButtons: [
                NavigationAlertButton("中间版本", action: .first, role: .destructive),
                NavigationAlertButton("最终版本", action: .first)
            ]
        )
        #expect(content.buttons.count == 1)
        #expect(String(localized: content.buttons[0].title) == "最终版本")
        #expect(content.buttons[0].role == .standard)
    }

    @Test func cancellationHasItsOwnSlotAndKeepsDisplayedIndicesAlignedWithActions() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息",
            firstButton: NavigationAlertButton("危险操作", action: Action.first, role: .destructive),
            additionalButtons: [NavigationAlertButton("其他操作", action: .second)],
            cancelButton: NavigationAlertCancelButton("取消", action: .cancel)
        )
        #expect(content.buttons.map(\.action) == [.first, .second])
        #expect(content.presentationButtons.map(\.action) == [.cancel, .first, .second])
        #expect(content.presentationButtons.map(\.isCancel) == [true, false, false])
        #expect(content.presentationButtons.map(\.isDestructive) == [false, true, false])
    }

    @Test func cancellationIsIndependentEvenWhenItsActionMatchesARegularButton() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息",
            firstButton: NavigationAlertButton("原文", action: Action.first),
            additionalButtons: [NavigationAlertButton("新版", action: .first)],
            cancelButton: NavigationAlertCancelButton("取消", action: .first)
        )
        #expect(content.buttons.count == 1)
        #expect(content.presentationButtons.map { String(localized: $0.title) } == ["取消", "新版"])
        #expect(content.presentationButtons.map(\.action) == [.first, .first])
        #expect(content.presentationButtons.map(\.isCancel) == [true, false])
    }

    @Test func cancellationOnlyIsStillANonemptyAlert() {
        let content = NavigationAlertContent(
            title: "标题", message: "消息", cancelButton: NavigationAlertCancelButton("关闭", action: Action.cancel)
        )
        #expect(content.buttons.isEmpty)
        #expect(content.presentationButtons.map(\.action) == [.cancel])
        #expect(content.presentationButtons.map(\.isCancel) == [true])
        #expect(content.presentationButtons.map(\.isDestructive) == [false])
    }
}
