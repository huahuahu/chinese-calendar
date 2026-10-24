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
        let context = try PreviewSampleData.makeContext(includesSampleData: !scene.isEmptyData)
        let selection = CalendarSelection(selectedDayIndex: scene.isEmptyData ? nil : scene.scenario.selectedDayIndex)
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
