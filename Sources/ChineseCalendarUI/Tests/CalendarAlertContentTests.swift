@testable import ChineseCalendarUI
import Foundation
import Testing

@MainActor
@Suite("业务提示的普通按钮与取消入口")
struct CalendarAlertContentTests {
    @Test func clearDataConfirmationSeparatesCancellationFromTheDestructiveAction() {
        let content = CalendarAlertContent.content(for: .clearDownloadedData, messages: [:])
        #expect(content.buttons.map(\.action) == [.clearDownloadedData])
        #expect(content.buttons.map(\.role) == [.destructive])
        #expect(content.cancelButton?.action == .cancel)
    }

    @Test(arguments: [
        CalendarAlert.clearDataSucceeded,
        .clearDataFailed(messageID: UUID()),
        .downloadFailed(messageID: UUID())
    ])
    func noticesKeepASingleAcknowledgement(route: CalendarAlert) {
        let content = CalendarAlertContent.content(for: route, messages: [:])
        #expect(content.buttons.map(\.action) == [.acknowledge])
        #expect(content.buttons.map(\.role) == [.standard])
        #expect(content.cancelButton == nil)
    }

    #if DEBUG
        @Test func debugNavigationKeepsItsExplicitCancelAndOpenHistoryActions() {
            let content = CalendarAlertContent.content(for: .debugNavigationChoice, messages: [:])
            #expect(content.buttons.map(\.action) == [.openHistory])
            #expect(content.cancelButton?.action == .cancel)
        }
    #endif
}
