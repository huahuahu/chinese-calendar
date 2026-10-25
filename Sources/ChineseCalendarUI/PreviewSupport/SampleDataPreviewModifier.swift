import SwiftUI

struct SampleDataPreviewModifier: PreviewModifier {
    var scenario: PreviewCalendarScenario = .modern

    static func makeSharedContext() throws -> SampleDataPreviewContext {
        try PreviewSampleData.makeContext(includesSampleData: true)
    }

    func body(
        content: Content,
        context: SampleDataPreviewContext
    ) -> some View {
        // makeSharedContext 按 modifier 类型缓存，不能在其中选择实例特有的场景。
        // 复用只读库，但每个 Host 用自己的初始选择创建独立 @State。
        SampleDataPreviewHost(
            content: content,
            context: SampleDataPreviewContext(
                modelContainer: context.modelContainer,
                selection: .day(index: scenario.selectedDayIndex),
                today: context.today
            )
        )
    }
}
