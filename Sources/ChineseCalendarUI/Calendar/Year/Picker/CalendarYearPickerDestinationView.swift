import SwiftUI

/// 按 sessionID 取得打开年份选择器时保存的会话，使用发起页的 CalendarSelection 和 ModelContext。
/// 选年结果经该会话回传给发起页，避免改到另一个日历页面的选择。
struct CalendarYearPickerDestinationView: View {
    let sessionID: UUID
    @Environment(CalendarHomeCoordinator.self) private var coordinator

    var body: some View {
        if let session = coordinator.yearPickerSessions[sessionID] {
            CalendarYearPickerView { yearNumber in
                coordinator.selectYear(yearNumber, sessionID: sessionID)
            }
            .environment(session.selection)
            .environment(\.modelContext, session.modelContext)
        }
    }
}
