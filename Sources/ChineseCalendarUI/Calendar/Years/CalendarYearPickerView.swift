import ChineseCalendarPersistence
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    private let yearSections: [CalendarYearSection]
    private let items: [CalendarYearPickerItem]
    private let availableYearNumbers: [Int]
    @ScaledMetric(relativeTo: .caption2) private var sectionIndexWidth: CGFloat = 24
    @State private var hasResolvedInitialScrollTarget = false
    @State private var scrollPosition: CalendarYearPickerItem.ID?

    init(
        years: [ChineseLunarYear],
        selectedYearNumber: Int?,
        selectYear: @escaping (Int) -> Void
    ) {
        self.selectedYearNumber = selectedYearNumber
        self.selectYear = selectYear
        let yearSections = CalendarYearSection.sections(for: years)
        self.yearSections = yearSections
        items = CalendarYearPickerItem.items(for: yearSections)
        availableYearNumbers = years.map(\.lunarYearNumber)
        _scrollPosition = State(initialValue: nil)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        switch item {
                        case let .section(section):
                            Text(section.title)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityAddTraits(.isHeader)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.background)
                        case let .year(year):
                            CalendarYearPickerRow(
                                year: year,
                                isSelected: year.lunarYearNumber == selectedYearNumber,
                                selectYear: {
                                    selectYear(year.lunarYearNumber)
                                }
                            )
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.trailing, sectionIndexWidth, for: .scrollContent)
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .onChange(of: availableYearNumbers, initial: true) {
                positionInitiallyIfNeeded()
            }

            CalendarYearSectionIndex(
                width: sectionIndexWidth,
                sections: yearSections,
                currentSectionID: scrollPosition?.sectionID
                    ?? selectedYearNumber.map(CalendarYearSection.signedCentury(lunarYearNumber:)),
                selectSection: { section in
                    scrollPosition = .section(section.id)
                }
            )
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

    private func positionInitiallyIfNeeded() {
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

        guard let target = Self.initialScrollTarget(
            selectedYearNumber: selectedYearNumber,
            availableYearNumbers: availableYearNumbers
        ) else {
            hasResolvedInitialScrollTarget = true
            return
        }

        hasResolvedInitialScrollTarget = true
        scrollPosition = .year(target)
    }
}
