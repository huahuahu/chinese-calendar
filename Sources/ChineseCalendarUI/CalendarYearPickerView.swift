import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct CalendarYearPickerView: View {
    let years: [ChineseLunarYear]
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void
    let dismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("农历年") {
                    ForEach(years, id: \.lunarYearNumber) { year in
                        Button {
                            selectYear(year.lunarYearNumber)
                        } label: {
                            HStack(spacing: 12) {
                                LunarYearRow(year: year)

                                Spacer()

                                if year.lunarYearNumber == selectedYearNumber {
                                    Image(systemSymbol: .checkmark)
                                        .font(.headline)
                                        .foregroundStyle(.tint)
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(year.lunarYearNumber == selectedYearNumber ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("年份选择器")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", action: dismiss)
                }
            }
        }
    }
}
