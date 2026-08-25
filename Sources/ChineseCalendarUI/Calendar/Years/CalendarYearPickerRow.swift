import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarYearPickerRow: View {
    let year: ChineseLunarYear
    let isSelected: Bool
    let selectYear: () -> Void

    var body: some View {
        Button(action: selectYear) {
            HStack(spacing: 12) {
                LunarYearRow(year: year)

                Spacer()

                if isSelected {
                    Image(systemSymbol: .checkmark)
                        .font(.headline)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        Divider()
            .padding(.leading)
    }
}
