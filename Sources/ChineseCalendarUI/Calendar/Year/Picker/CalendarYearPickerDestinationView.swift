import SwiftUI

/// 页面参数来自本次路由；关闭命令被接受后，通过 Binding 回传所选年份。
struct CalendarYearPickerDestinationView: View {
    @Binding var selection: Int?
    @Environment(CalendarPresentationContext.self) private var presentation

    var body: some View {
        CalendarYearPickerView(selectedYearNumber: selection) { yearNumber in
            guard presentation.dismiss().isAccepted else { return }
            selection = yearNumber
        }
    }
}
