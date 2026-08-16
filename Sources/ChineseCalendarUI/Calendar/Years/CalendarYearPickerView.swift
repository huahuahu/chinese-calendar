import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    let years: [ChineseLunarYear]
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    var body: some View {
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
    }
}
