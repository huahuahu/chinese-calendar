@testable import ChineseCalendarUI
import NavigationCore
import Testing

@MainActor
@Suite("业务提示的普通按钮与取消入口")
struct CalendarAlertContentTests {
    @Test func clearDataConfirmationSeparatesCancellationFromTheDestructiveAction() {
        let content = CalendarAlertContent.clearDownloadedData
        #expect(content.buttons.map(\.action) == [.clear])
        #expect(content.buttons.map(\.role) == [.destructive])
        #expect(content.cancelButton?.action == .cancel)
    }

    @Test func noticesKeepASingleAcknowledgement() {
        var contents: [NavigationAlertContent<CalendarNoticeAction>] = [
            CalendarAlertContent.clearDataSucceeded,
            CalendarAlertContent.clearDataFailed(message: nil),
            CalendarAlertContent.downloadFailed(message: nil)
        ]
        #if DEBUG
            contents.append(CalendarAlertContent.debugNotice(number: 1))
        #endif
        for content in contents {
            #expect(content.buttons.map(\.action) == [.acknowledge])
            #expect(content.buttons.map(\.role) == [.standard])
            #expect(content.cancelButton == nil)
        }
    }

    #if DEBUG
        @Test func debugNavigationKeepsItsExplicitCancelAndOpenHistoryActions() {
            let content = CalendarAlertContent.debugNavigationChoice
            #expect(content.buttons.map(\.action) == [.openHistory])
            #expect(content.cancelButton?.action == .cancel)
        }
    #endif
}
