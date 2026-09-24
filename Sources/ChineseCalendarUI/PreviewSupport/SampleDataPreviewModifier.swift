import SwiftUI

struct SampleDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> SampleDataPreviewContext {
        try PreviewSampleData.makeContext(includesSampleData: true)
    }

    func body(
        content: Content,
        context: SampleDataPreviewContext
    ) -> some View {
        SampleDataPreviewHost(content: content, context: context)
    }
}
