import SwiftUI

/// 为每个 Preview 隔离会变化的 Environment 模型，同时复用只读 SwiftData 示例库。
struct SampleDataPreviewHost: View {
    private let content: PreviewModifierContent
    private let context: SampleDataPreviewContext

    @State private var selection: CalendarSelection
    @State private var today: CalendarToday

    init(
        content: PreviewModifierContent,
        context: SampleDataPreviewContext
    ) {
        self.content = content
        self.context = context
        _selection = State(
            initialValue: CalendarSelection(selectedDayIndex: context.selectedDayIndex)
        )
        _today = State(initialValue: CalendarToday(date: context.today))
    }

    var body: some View {
        content
            .modelContainer(context.modelContainer)
            .environment(selection)
            .environment(today)
            .environment(\.calendarStoreContentLevel, .full)
    }
}
