import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

public struct CalendarHomeView: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @State private var selectedYearNumber: Int?
    @State private var selectedMonthIndex: Int?

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedYearNumber) {
                Section("农历年") {
                    ForEach(years, id: \.lunarYearNumber) { year in
                        LunarYearRow(year: year)
                            .tag(year.lunarYearNumber)
                    }
                }
            }
            .navigationTitle("年份")
        } detail: {
            Group {
                if let selectedYear {
                    LunarYearDetailView(
                        year: selectedYear,
                        selectedMonthIndex: $selectedMonthIndex,
                        canSelectPreviousYear: canSelectPreviousYear,
                        canSelectNextYear: canSelectNextYear,
                        selectPreviousYear: selectPreviousYear,
                        selectNextYear: selectNextYear
                    )
                } else {
                    ContentUnavailableView {
                        Label("Chinese Calendar", systemImage: "calendar")
                    } description: {
                        Text(emptyStateDescription)
                    }
                }
            }
        }
        .task {
            selectDefaultYearIfNeeded()
        }
        .onChange(of: years.map(\.lunarYearNumber)) {
            selectDefaultYearIfNeeded()
        }
        .onChange(of: selectedYearNumber) {
            selectedMonthIndex = nil
        }
    }

    private var selectedYear: ChineseLunarYear? {
        guard let selectedYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == selectedYearNumber }
    }

    private var selectedYearIndex: Int? {
        guard let selectedYearNumber else {
            return nil
        }

        return years.firstIndex { $0.lunarYearNumber == selectedYearNumber }
    }

    private var canSelectPreviousYear: Bool {
        guard let selectedYearIndex else {
            return false
        }

        return selectedYearIndex > years.startIndex
    }

    private var canSelectNextYear: Bool {
        guard let selectedYearIndex else {
            return false
        }

        return selectedYearIndex < years.index(before: years.endIndex)
    }

    private var emptyStateDescription: String {
        if years.isEmpty {
            return "正在加载 SwiftData 日历数据。"
        }

        return "请选择一个农历年。"
    }

    private func selectDefaultYearIfNeeded() {
        guard selectedYear == nil else {
            return
        }

        let fallbackYearNumber = ChineseLunarCalendar.yearNumber()
        selectedYearNumber = years.first { $0.lunarYearNumber == fallbackYearNumber }?.lunarYearNumber
            ?? years.last?.lunarYearNumber
    }

    private func selectPreviousYear() {
        guard let selectedYearIndex, selectedYearIndex > years.startIndex else {
            return
        }

        selectedYearNumber = years[years.index(before: selectedYearIndex)].lunarYearNumber
    }

    private func selectNextYear() {
        guard let selectedYearIndex, selectedYearIndex < years.index(before: years.endIndex) else {
            return
        }

        selectedYearNumber = years[years.index(after: selectedYearIndex)].lunarYearNumber
    }
}

#Preview {
    CalendarHomeView()
}
