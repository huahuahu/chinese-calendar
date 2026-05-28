import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

public struct CalendarHomeView: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @State private var appState: CalendarAppState

    @MainActor
    public init(appState: CalendarAppState = CalendarAppState()) {
        _appState = State(initialValue: appState)
    }

    @available(*, deprecated, message: "CalendarHomeView now selects the current lunar year automatically.")
    @MainActor
    public init(selectedDate _: ChineseCalendarDate?) {
        _appState = State(initialValue: CalendarAppState())
    }

    public var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: $state.columnVisibility) {
            List(selection: $state.route) {
                Section("农历年") {
                    ForEach(years, id: \.lunarYearNumber) { year in
                        LunarYearRow(year: year)
                            .tag(CalendarAppState.Route.lunarYear(year.lunarYearNumber))
                    }
                }
            }
            .navigationTitle("年份")
        } detail: {
            Group {
                if let selectedYear {
                    LunarYearDetailView(
                        year: selectedYear,
                        state: state,
                        yearNumbers: yearNumbers
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
    }

    private var yearNumbers: [Int] {
        years.map(\.lunarYearNumber)
    }

    private var selectedYear: ChineseLunarYear? {
        guard case let .lunarYear(selectedYearNumber) = appState.route else {
            return nil
        }

        return years.first { $0.lunarYearNumber == selectedYearNumber }
    }

    private var emptyStateDescription: String {
        if years.isEmpty {
            return "正在加载 SwiftData 日历数据。"
        }

        return "请选择一个农历年。"
    }

    private func selectDefaultYearIfNeeded() {
        guard !years.isEmpty else {
            ChineseCalendarLog.ui.debug("CalendarHomeView is waiting for SwiftData years")
            return
        }

        guard let defaultYearNumber = appState.selectDefaultYearIfNeeded(from: yearNumbers) else {
            return
        }

        ChineseCalendarLog.ui.info("Selected default lunar year \(defaultYearNumber)")
    }
}

#Preview {
    CalendarHomeView()
}
