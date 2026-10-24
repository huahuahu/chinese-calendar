import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import NavigationCore
import Observation
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("导航树共享数据环境", .serialized)
struct CalendarStoreEnvironmentTests {
    @Test func replacingTheSameArtifactChangesTheNavigationStoreIdentity() throws {
        let first = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let second = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let store = ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
        let firstIdentity = store.storeIdentity(container: first, contentLevel: .base, identityToken: "same")
        #expect(firstIdentity == store.storeIdentity(container: first, contentLevel: .base, identityToken: "same"))
        #expect(firstIdentity != store.storeIdentity(container: second, contentLevel: .base, identityToken: "same"))
    }

    @Test(.timeLimit(.minutes(1)))
    func rootAndModalShareStoreAndReplacementKeepsPresentationIdentity() async throws {
        let first = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let second = try PreviewSampleData.makeModelContainer()
        let expectedYears = try second.mainContext.fetch(FetchDescriptor<ChineseLunarYear>()).count
        let router = NavigationRouter<CalendarTab, StoreEnvironmentDestination, CalendarAlert>(
            rootDestination: .root, initialStack: .scope(.years), rootDestinations: [.scope(.years): .probe]
        )
        let store = ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
        let state = StoreEnvironmentState(state: .ready(container: first, contentLevel: .base, identityToken: "first"))
        let recorder = StoreEnvironmentRecorder()
        let host = try await NavigationTestHost.show(StoreEnvironmentHost(
            router: router, store: store, state: state, recorder: recorder
        ))
        defer { host.removeFromWindow() }
        try await host.waitUntil { !recorder.contexts.isEmpty }
        #expect(recorder.contexts.allSatisfy { $0 === first.mainContext })
        let root = router.rootPresentation
        let request = root.present(.sheet(.probe, rootDestinations: [.primary: .probe]))
        try #require(request.result == .applied)
        _ = try await host.waitForPresentation()
        try await host.waitUntil { recorder.presentations.contains { $0 !== root } }
        let modal = try #require(recorder.presentations.first { $0 !== root })
        #expect(recorder.contexts.allSatisfy { $0 === first.mainContext })
        #expect(recorder.stores.allSatisfy { $0 === store })

        recorder.contexts.removeAll()
        recorder.levels.removeAll()
        recorder.yearCounts.removeAll()
        state.state = .ready(container: second, contentLevel: .full, identityToken: "second")
        try await host.waitUntil { recorder.contexts.contains { $0 === second.mainContext } }
        #expect(recorder.levels.last == .full)
        #expect(recorder.yearCounts.last == expectedYears)
        #expect(modal.isPresented)
        #expect(recorder.presentations.contains { $0 === modal })
        request.handle?.dismiss()
        try await host.waitUntil { host.presentedViewController() == nil }
        await host.close()
    }

    @Test func unavailableStorePreservesAnInheritedPreviewEnvironment() throws {
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let router = NavigationRouter<CalendarTab, StoreEnvironmentDestination, CalendarAlert>(
            rootDestination: .root, initialStack: .scope(.years), rootDestinations: [.scope(.years): .probe]
        )
        let recorder = StoreEnvironmentRecorder()
        let content = StoreEnvironmentProbe(recorder: recorder)
            .environment(router.rootPresentation)
            .calendarStoreEnvironment(state: .starting)
            .modelContainer(container)
            .environment(\.calendarStoreContentLevel, .full)

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(recorder.contexts.last?.container === container)
        #expect(recorder.levels.last == .full)
    }
}

private final class StoreEnvironmentRecorder {
    var contexts: [ModelContext] = []
    var levels: [ChineseCalendarSeedStoreContentLevel] = []
    var stores: [ChineseCalendarStoreCoordinator?] = []
    var presentations: [NavigationPresentationContext<CalendarTab, StoreEnvironmentDestination, CalendarAlert>] = []
    var yearCounts: [Int] = []
}

private struct StoreEnvironmentConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = StoreEnvironmentDestination
    typealias AlertRoute = CalendarAlert
    let recorder: StoreEnvironmentRecorder
    var state: StoreEnvironmentState?

    func destination(for destination: StoreEnvironmentDestination) -> some View {
        StoreEnvironmentProbe(recorder: recorder)
            .calendarStoreContent(state: state?.state)
    }
}

private struct StoreEnvironmentProbe: View {
    let recorder: StoreEnvironmentRecorder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendarStoreContentLevel) private var contentLevel
    @Environment(ChineseCalendarStoreCoordinator.self) private var store: ChineseCalendarStoreCoordinator?
    @Environment(NavigationPresentationContext<CalendarTab, StoreEnvironmentDestination, CalendarAlert>
        .self) private var presentation
    @Query private var years: [ChineseLunarYear]

    var body: some View {
        recorder.contexts.append(modelContext)
        recorder.levels.append(contentLevel)
        recorder.stores.append(store)
        recorder.presentations.append(presentation)
        recorder.yearCounts.append(years.count)
        return Color.clear.frame(width: 10, height: 10)
    }
}

/// 探针自行提供内容；根层和模态均显式声明栈根，检验模态边界的环境继承。
private enum StoreEnvironmentDestination: NavigationDestination {
    case root, probe
    var providesNavigationContainer: Bool {
        true
    }
}

@MainActor
@Observable
private final class StoreEnvironmentState {
    var state: CalendarStoreBootstrapState
    init(state: CalendarStoreBootstrapState) {
        self.state = state
    }
}

private struct StoreEnvironmentHost: View {
    let router: NavigationRouter<CalendarTab, StoreEnvironmentDestination, CalendarAlert>
    let store: ChineseCalendarStoreCoordinator
    let state: StoreEnvironmentState
    let recorder: StoreEnvironmentRecorder

    var body: some View {
        NavigationRootView(context: router.rootPresentation)
            .navigationHost(
                context: router.rootPresentation,
                configuration: StoreEnvironmentConfiguration(recorder: recorder, state: state)
            )
            .environment(store)
            .calendarStoreEnvironment(state: state.state)
    }
}
