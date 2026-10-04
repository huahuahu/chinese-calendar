import ChineseCalendarLogging
import ChineseCalendarPersistence
import Combine
import Foundation
import SwiftData
import SwiftUI

/// 把年月日导航地址解析为一次性的选中日，并为日历功能子树提供共享环境。
struct LunarYearDestinationView: View {
    let landing: LunarCalendarLanding

    @State private var selection = CalendarSelection()
    @State private var today = CalendarToday()

    var body: some View {
        LunarYearSelectionHost(landing: landing)
            .environment(selection)
            .environment(today)
    }
}

/// 隔离环境读取与日期刷新副作用，页面本身只表达选中日对应的内容。
private struct LunarYearSelectionHost: View {
    @Environment(CalendarSelection.self) private var selection
    @Environment(CalendarToday.self) private var today
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    let landing: LunarCalendarLanding

    var body: some View {
        CalendarPageView(selectedDayIndex: selection.selectedDayIndex)
            .task(id: storeContentLevel) {
                resolveInitialSelectionIfNeeded()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }

                refreshToday()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
                    .receive(on: RunLoop.main)
            ) { _ in
                refreshToday()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
                    .receive(on: RunLoop.main)
            ) { _ in
                refreshToday()
            }
    }

    private func refreshToday() {
        today.refresh()
        resolveInitialSelectionIfNeeded()
    }

    private func resolveInitialSelectionIfNeeded() {
        let resolver = CalendarSelectionResolver(modelContext: modelContext)

        do {
            if let selectedDayIndex = selection.selectedDayIndex, try resolver.contains(dayIndex: selectedDayIndex) {
                return
            }

            try selection.select(
                dayIndex: resolver.selectedDayIndex(
                    for: landing,
                    todayJulianDayNumber: today.julianDayNumber
                )
            )
        } catch {
            ChineseCalendarLog.ui.error("无法解析日历初始选中日：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }
}
