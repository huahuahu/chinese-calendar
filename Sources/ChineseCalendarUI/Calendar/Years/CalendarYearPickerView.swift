import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    let years: [ChineseLunarYear]
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    @State private var hasResolvedInitialScrollTarget = false

    var body: some View {
        ScrollViewReader { proxy in
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
                        .id(year.lunarYearNumber)
                        .accessibilityAddTraits(year.lunarYearNumber == selectedYearNumber ? .isSelected : [])
                    }
                }
            }
            .onChange(of: years.map(\.lunarYearNumber), initial: true) {
                positionInitiallyIfNeeded(using: proxy)
            }
        }
        .navigationTitle("年份选择器")
    }

    static func initialScrollTarget(
        selectedYearNumber: Int?,
        availableYearNumbers: [Int]
    ) -> Int? {
        guard let selectedYearNumber,
              availableYearNumbers.contains(selectedYearNumber)
        else {
            return nil
        }

        return selectedYearNumber
    }

    private func positionInitiallyIfNeeded(using proxy: ScrollViewProxy) {
        guard !hasResolvedInitialScrollTarget else {
            return
        }

        guard selectedYearNumber != nil else {
            hasResolvedInitialScrollTarget = true
            return
        }

        let availableYearNumbers = years.map(\.lunarYearNumber)
        guard !availableYearNumbers.isEmpty else {
            return
        }

        hasResolvedInitialScrollTarget = true
        guard let target = Self.initialScrollTarget(
            selectedYearNumber: selectedYearNumber,
            availableYearNumbers: availableYearNumbers
        ) else {
            return
        }

        proxy.scrollTo(target, anchor: .center)
    }
}
