import SwiftUI

/// 使用本次配置直接传入的发起页资源，关闭获准后再向同一 feature 回传结果。
struct CalendarYearPickerDestinationView: View {
    let feature: CalendarYearFeature
    let session: CalendarYearPickerSession
    @Environment(CalendarPresentationContext.self) private var presentation

    var body: some View {
        CalendarYearPickerView { yearNumber in
            guard presentation.dismiss().isAccepted else { return }
            feature.selectYear(yearNumber, session: session)
        }
        .environment(session.selection)
        .environment(\.modelContext, session.modelContext)
        .disabled(!session.acceptsResult)
    }
}
