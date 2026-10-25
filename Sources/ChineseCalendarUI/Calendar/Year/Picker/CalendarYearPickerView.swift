import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示可选农历年列表，由所在 NavigationStack 提供导航容器。
struct CalendarYearPickerView: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]

    let selectedYearNumber: Int?
    let selectYear: (Int) -> Void

    @State private var hasResolvedInitialScrollTarget = false
    @State private var isListReady = false

    init(selectedYearNumber: Int? = nil, selectYear: @escaping (Int) -> Void) {
        self.selectedYearNumber = selectedYearNumber
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
            .onChange(of: selectedYearNumber) {
                positionInitiallyIfNeeded(using: proxy)
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.containerSize.height > 0 && geometry.contentSize.height > 0
            } action: { _, isReady in
                isListReady = isReady
                positionInitiallyIfNeeded(using: proxy)
            }
        }
        .navigationTitle(CalendarStringKey.Calendar.YearPicker.title)
    }

    private var yearSections: [CalendarYearSection] {
        CalendarYearSection.sections(for: years)
    }

    private var availableYearNumbers: [Int] {
        years.map(\.lunarYearNumber)
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
        // 模态内容先建立数据、后完成 List 布局，首个 onChange 可能早于滚动容器就绪。
        guard isListReady, !hasResolvedInitialScrollTarget else {
            return
        }

        guard let target = Self.initialScrollTarget(
            selectedYearNumber: selectedYearNumber,
            availableYearNumbers: availableYearNumbers
        ) else {
            return
        }

        hasResolvedInitialScrollTarget = true
        proxy.scrollTo(CalendarYearPickerScrollTarget.year(target), anchor: .center)
    }
}

/// 年份与世纪分组可能使用相同整数，滚动目标必须与分组身份分开。
private enum CalendarYearPickerScrollTarget: Hashable {
    case year(Int)
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
                .id(CalendarYearPickerScrollTarget.year(year.lunarYearNumber))
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
        let resolver = CalendarSelectionResolver(modelContext: modelContext)
        let selectedYear = selection.value.flatMap { try? resolver.yearNumber(for: $0) }
        CalendarYearPickerView(selectedYearNumber: selectedYear) { yearNumber in
            selection.select(try? resolver.selection(
                for: .year(number: yearNumber),
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
