import ChineseCalendarPersistence
import Combine
import Foundation
import SwiftData
import SwiftUI

/// 把年月日导航地址解析为月或日选择，并为日历功能子树提供共享环境。
struct LunarYearDestinationView: View {
    let landing: LunarCalendarLanding

    @State private var feature = CalendarYearFeature()
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?

    var body: some View {
        LunarYearSelectionHost(landing: landing)
            .calendarStoreContent(state: storeCoordinator?.state)
            .environment(feature)
            .environment(feature.selection)
            .environment(feature.today)
    }
}

/// 隔离环境读取与日期刷新副作用，页面本身只表达选中月或日对应的内容。
private struct LunarYearSelectionHost: View {
    @Environment(CalendarYearFeature.self) private var feature
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?
    @Environment(CalendarSelection.self) private var selection
    @Environment(CalendarToday.self) private var today
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    let landing: LunarCalendarLanding

    var body: some View {
        CalendarPageView(selection: selection.value)
            .task(id: ObjectIdentifier(modelContext)) {
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
        feature.connect(modelContext: modelContext, storeCoordinator: storeCoordinator)
        guard feature.modelContext === modelContext else { return }
        feature.resolveSelectionIfNeeded(for: landing)
    }
}
