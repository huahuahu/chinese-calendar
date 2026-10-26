import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import SwiftData
import SwiftUI

/// 每次截图独占示例库、可变页面状态和偏好，避免场景间相互影响。
@MainActor
struct SnapshotSampleHost: View {
    private let scene: SnapshotScene
    private let modelContainer: ModelContainer
    private let preferences: Preferences

    @State private var coordinator: CalendarHomeCoordinator
    @State private var selection: CalendarSelection
    @State private var today: CalendarToday
    @State private var feature: CalendarYearFeature
    @State private var storeCoordinator: ChineseCalendarStoreCoordinator?

    init(scene: SnapshotScene) throws {
        let context = try scene == .baseCalendar
            ? PreviewBaseCalendarData.makeContext()
            : PreviewSampleData.makeContext(includesSampleData: !scene.isEmptyData)
        if scene == .history {
            try Self.insertTimelinePeriods(into: context.modelContainer.mainContext)
        }
        let initialSelection: CalendarSelectionValue? = scene == .baseCalendar || scene.isEmptyData
            ? context.selection
            : .day(index: scene.scenario.selectedDayIndex)
        let selection = CalendarSelection(value: initialSelection)
        let today = CalendarToday(date: context.today)
        let feature = CalendarYearFeature(selection: selection, today: today)
        let coordinator = CalendarHomeCoordinator(router: CalendarRouter(selectedTab: scene.tab))
        feature.connect(modelContext: context.modelContainer.mainContext, storeCoordinator: nil)

        if scene == .selectedHistory {
            let navigation = coordinator.router.navigation.rootPresentation.context(for: .scope(.history))
            let result = navigation.setRootDestination(.historyDetail(
                orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID,
                section: .emperors
            ))
            guard result.isApplied else { throw FixtureError.rejectedHistoryRoot }
        }

        self.scene = scene
        modelContainer = context.modelContainer
        preferences = try Preferences()
        _coordinator = State(initialValue: coordinator)
        _selection = State(initialValue: selection)
        _today = State(initialValue: today)
        _feature = State(initialValue: feature)
        _storeCoordinator = State(initialValue: scene == .settingsStarting
            ? ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
            : nil)
    }

    var body: some View {
        scene.content
            .calendarNavigationHost(coordinator: coordinator, storeCoordinator: storeCoordinator)
            .modelContainer(modelContainer)
            .environment(selection)
            .environment(today)
            .environment(feature)
            .environment(\.calendarStoreContentLevel, scene == .baseCalendar ? .base : .full)
            .defaultAppStorage(preferences.store)
    }

    private enum FixtureError: Error {
        case rejectedHistoryRoot
        case unavailablePreferences
        case missingHistoryTradition
    }

    /// 在明代示例后补充连续节点，覆盖首尾连线、长名称和缺少详情的行。
    private static func insertTimelinePeriods(into context: ModelContext) throws {
        let periods = try context.fetch(FetchDescriptor<OrthodoxPeriod>())
        guard let tradition = periods.first?.tradition else {
            throw FixtureError.missingHistoryTradition
        }
        let fixtures = [
            (id: "qing", name: "清", start: 1644, end: 1912, hasDetails: true),
            (id: "republic", name: "中华民国", start: 1912, end: 1949, hasDetails: false),
            (id: "people-republic", name: "中华人民共和国", start: 1949, end: 2026, hasDetails: false)
        ]
        for (index, fixture) in fixtures.enumerated() {
            let id = "snapshot-\(fixture.id)"
            let start = ChineseDateExpression(
                id: "\(id)-start", precision: .year, index: fixture.start, sourceText: "\(fixture.start)年"
            )
            let end = ChineseDateExpression(
                id: "\(id)-end", precision: .year, index: fixture.end, sourceText: "\(fixture.end)年"
            )
            let dynasty = Dynasty(id: id, name: fixture.name, claimedStartDate: start, claimedEndDate: end)
            let period = OrthodoxPeriod(
                id: "\(id)-period", sequenceIndex: index + 1, segmentIndex: 0, segmentName: fixture.name,
                tradition: tradition, dynasty: dynasty,
                startBoundary: OrthodoxBoundary(id: "\(id)-start-boundary", tradition: tradition, date: start),
                endBoundary: OrthodoxBoundary(id: "\(id)-end-boundary", tradition: tradition, date: end)
            )
            if !fixture.hasDetails {
                period.dynasty = nil
            }
            context.insert(period)
        }
        try context.save()
    }

    /// 设置页的 AppStorage 只读写本次截图的独立域，宿主释放后删除。
    private final class Preferences {
        let store: UserDefaults
        private let suiteName: String

        init() throws {
            let suiteName = "ChineseCalendarSnapshot-\(UUID().uuidString)"
            guard let store = UserDefaults(suiteName: suiteName) else {
                throw FixtureError.unavailablePreferences
            }
            self.suiteName = suiteName
            self.store = store
            store.set(CalendarColorSchemePreference.system.rawValue, forKey: CalendarColorSchemePreference.storageKey)
        }

        isolated deinit {
            store.removePersistentDomain(forName: suiteName)
        }
    }
}
