import SwiftUI

/// 用发起页的选择与 ModelContext 构建年份选择器，不借用根页面的日历状态。
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
