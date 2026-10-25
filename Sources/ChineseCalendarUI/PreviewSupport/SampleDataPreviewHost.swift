import SwiftUI

/// 为每个 Preview 隔离会变化的 Environment 模型，同时复用只读 SwiftData 示例库。
struct SampleDataPreviewHost: View {
    private let content: PreviewModifierContent
    private let context: SampleDataPreviewContext

    @State private var navigationCoordinator = CalendarHomeCoordinator()
    @State private var selection: CalendarSelection
    @State private var today: CalendarToday
    @State private var feature: CalendarYearFeature

    init(
        content: PreviewModifierContent,
        context: SampleDataPreviewContext
    ) {
        self.content = content
        self.context = context
        let selection = CalendarSelection(value: context.selection)
        let today = CalendarToday(date: context.today)
        _selection = State(initialValue: selection)
        _today = State(initialValue: today)
        _feature = State(initialValue: CalendarYearFeature(selection: selection, today: today))
    }

    var body: some View {
        content
            .calendarNavigationHost(coordinator: navigationCoordinator)
            .modelContainer(context.modelContainer)
            .environment(selection)
            .environment(today)
            .environment(feature)
            .onAppear { feature.connect(modelContext: context.modelContainer.mainContext, storeCoordinator: nil) }
            .environment(\.calendarStoreContentLevel, context.contentLevel)
    }
}
