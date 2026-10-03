import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    @Environment(CalendarSelection.self) private var selection
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]

    let selectYear: (Int) -> Void

    @State private var hasResolvedInitialScrollTarget = false

    init(selectYear: @escaping (Int) -> Void) {
        self.selectYear = selectYear
    }

    var body: some View {
        ScrollViewReader { proxy in
            CalendarYearPickerList(
                sections: yearSections,
                selectedYearNumber: selectedYearNumber,
                selectYear: selectYear
            )
            .onChange(of: availableYearNumbers, initial: true) {
                positionInitiallyIfNeeded(using: proxy)
            }
        }
        .navigationTitle("年份选择器")
    }

    private var yearSections: [CalendarYearSection] {
        CalendarYearSection.sections(for: years)
    }

    private var availableYearNumbers: [Int] {
        years.map(\.lunarYearNumber)
    }

    private var selectedYearNumber: Int? {
        try? CalendarSelectionResolver(modelContext: modelContext)
            .yearNumber(forDayIndex: selection.selectedDayIndex)
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

        guard let target = Self.initialScrollTarget(
            selectedYearNumber: selectedYearNumber,
            availableYearNumbers: availableYearNumbers
        ) else {
            hasResolvedInitialScrollTarget = true
            return
        }

        hasResolvedInitialScrollTarget = true
        proxy.scrollTo(target, anchor: .center)
    }
}

private struct CalendarYearPickerList: View {
    let sections: [CalendarYearSection]
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    var body: some View {
        List {
            ForEach(sections) { section in
                CalendarYearPickerSection(
                    section: section,
                    selectedYearNumber: selectedYearNumber,
                    selectYear: selectYear
                )
            }
        }
    }
}

private struct CalendarYearPickerSection: View {
    let section: CalendarYearSection
    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    var body: some View {
        Section(section.title) {
            ForEach(section.years, id: \.lunarYearNumber) { year in
                CalendarYearPickerRow(
                    year: year,
                    isSelected: year.lunarYearNumber == selectedYearNumber,
                    selectYear: selectYear
                )
                .id(year.lunarYearNumber)
            }
        }
        .sectionIndexLabel(section.indexTitle)
    }
}

private struct CalendarYearPickerRow: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 12
    }

    let year: ChineseLunarYear
    let isSelected: Bool
    let selectYear: (Int) -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: Constants.contentSpacing) {
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select() {
        selectYear(year.lunarYearNumber)
    }
}

private struct CalendarYearPickerPreviewContent: View {
    @Environment(CalendarSelection.self) private var selection
    @Environment(CalendarToday.self) private var today
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CalendarYearPickerView { yearNumber in
            let resolver = CalendarSelectionResolver(modelContext: modelContext)
            selection.select(dayIndex: try? resolver.selectedDayIndex(
                inYear: yearNumber,
                todayJulianDayNumber: today.julianDayNumber
            ))
        }
    }
}

#Preview("示例数据", traits: .sampleData) {
    NavigationStack {
        CalendarYearPickerPreviewContent()
    }
}

#Preview("有可能空白", traits: .emptySampleData) {
    NavigationStack {
        CalendarYearPickerView { _ in }
    }
}

#Preview("公元前与公元 · 不显示公元 0 年", traits: .sampleData(.beforeCommonEra)) {
    NavigationStack {
        CalendarYearPickerPreviewContent()
    }
}
