import SwiftUI

struct BaseSampleDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> SampleDataPreviewContext {
        try PreviewBaseCalendarData.makeContext()
    }

    func body(
        content: Content,
        context: SampleDataPreviewContext
    ) -> some View {
        SampleDataPreviewHost(content: content, context: context)
    }
}
