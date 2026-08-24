import ChineseCalendarPersistence
import SwiftData
import SwiftUI

/// 显示年份选择 destination，并将选择结果返回给发起选择的页面。
struct CalendarYearPickerDestinationView: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @Environment(\.dismiss) private var dismiss
    let destination: CalendarYearPickerDestination

    var body: some View {
        CalendarYearPickerView(
            years: years,
            selectedYearNumber: destination.initialYearNumber,
            selectYear: selectYear
        )
        .onDisappear(perform: destination.commitSelectionIfNeeded)
    }

    private func selectYear(_ yearNumber: Int) {
        destination.prepareSelection(yearNumber)
        dismiss()
    }
}
