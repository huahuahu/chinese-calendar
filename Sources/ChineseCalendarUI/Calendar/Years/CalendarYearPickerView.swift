import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    private let yearSections: [CalendarYearSection]
    private let availableYearNumbers: [Int]
    @State private var hasResolvedInitialScrollTarget = false

    init(
        years: [ChineseLunarYear],
        selectedYearNumber: Int?,
        selectYear: @escaping (Int) -> Void
    ) {
        self.selectedYearNumber = selectedYearNumber
        self.selectYear = selectYear
        yearSections = CalendarYearSection.sections(for: years)
        availableYearNumbers = years.map(\.lunarYearNumber)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(yearSections) { section in
                    Section(section.title) {
                        ForEach(section.years, id: \.lunarYearNumber) { year in
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
                    .sectionIndexLabel(section.indexTitle)
                }
            }
            .onChange(of: availableYearNumbers, initial: true) {
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
