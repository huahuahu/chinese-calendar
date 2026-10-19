import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import NavigationCore
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("导航树共享数据环境")
struct CalendarStoreEnvironmentTests {
    @Test func rootAndModalShareStoreEnvironmentWhileKeepingTheirOwnPresentation() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let expectedYears = try container.mainContext.fetch(FetchDescriptor<ChineseLunarYear>()).count
        let coordinator = CalendarHomeCoordinator()
        let store = ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
        let root = coordinator.router.navigation.rootPresentation
        #expect(root.present(.downloadDetails))
        let node = try #require(coordinator.router.sheet)
        let modal = coordinator.router.navigation.presentationContext(for: node)
        let recorder = StoreEnvironmentRecorder()
        let content = VStack {
            StoreEnvironmentProbe(recorder: recorder)
            NavigationPresentationNodeView(node: node, context: modal)
        }
        .navigationHost(context: root, configuration: StoreEnvironmentConfiguration(recorder: recorder))
        .environment(store)
        .calendarStoreEnvironment(state: .ready(container: container, contentLevel: .full, identityToken: "first"))

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(!recorder.contexts.isEmpty)
        #expect(recorder.contexts.allSatisfy { $0 === container.mainContext })
        #expect(recorder.levels.allSatisfy { $0 == .full })
        #expect(recorder.stores.allSatisfy { $0 === store })
        #expect(expectedYears > 0)
        #expect(recorder.yearCounts.allSatisfy { $0 == expectedYears })
        #expect(Set(recorder.presentations) == [root.id, modal.id])
    }

    @Test func replacingStoreUpdatesTheEnvironmentWithoutChangingPresentationIdentity() throws {
        let first = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let second = try PreviewSampleData.makeModelContainer()
        let expectedYears = try second.mainContext.fetch(FetchDescriptor<ChineseLunarYear>()).count
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.rootPresentation
        #expect(root.present(.downloadDetails))
        let node = try #require(coordinator.router.sheet)
        let modal = coordinator.router.navigation.presentationContext(for: node)
        let recorder = StoreEnvironmentRecorder()
        let content = NavigationPresentationNodeView(node: node, context: modal)
            .navigationHost(context: root, configuration: StoreEnvironmentConfiguration(recorder: recorder))
        let renderer = ImageRenderer(content: content.calendarStoreEnvironment(
            state: .ready(container: first, contentLevel: .base, identityToken: "first")
        ))
        #expect(renderer.cgImage != nil)
        #expect(recorder.contexts.last === first.mainContext)
        #expect(recorder.levels.last == .base)
        #expect(recorder.yearCounts.last == 0)

        renderer.content = content.calendarStoreEnvironment(
            state: .ready(container: second, contentLevel: .full, identityToken: "second")
        )
        #expect(renderer.cgImage != nil)
        #expect(recorder.contexts.last === second.mainContext)
        #expect(recorder.levels.last == .full)
        #expect(expectedYears > 0)
        #expect(recorder.yearCounts.last == expectedYears)
        #expect(Set(recorder.presentations) == [modal.id])
        #expect(coordinator.router.sheet === node)
        #expect(modal.isActive)
    }

    @Test func unavailableStorePreservesAnInheritedPreviewEnvironment() throws {
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let coordinator = CalendarHomeCoordinator()
        let recorder = StoreEnvironmentRecorder()
        let content = StoreEnvironmentProbe(recorder: recorder)
            .environment(coordinator.router.navigation.rootPresentation)
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
    var presentations: [NavigationLayerID] = []
    var yearCounts: [Int] = []
}

private struct StoreEnvironmentConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert
    let recorder: StoreEnvironmentRecorder

    func destination(for destination: CalendarDestination) -> some View {
        StoreEnvironmentProbe(recorder: recorder)
    }

    func providesNavigationStack(for destination: CalendarDestination) -> Bool {
        false
    }
}

private struct StoreEnvironmentProbe: View {
    let recorder: StoreEnvironmentRecorder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendarStoreContentLevel) private var contentLevel
    @Environment(ChineseCalendarStoreCoordinator.self) private var store: ChineseCalendarStoreCoordinator?
    @Environment(CalendarPresentationContext.self) private var presentation
    @Query private var years: [ChineseLunarYear]

    var body: some View {
        recorder.contexts.append(modelContext)
        recorder.levels.append(contentLevel)
        recorder.stores.append(store)
        recorder.presentations.append(presentation.id)
        recorder.yearCounts.append(years.count)
        return Color.clear.frame(width: 10, height: 10)
    }
}
