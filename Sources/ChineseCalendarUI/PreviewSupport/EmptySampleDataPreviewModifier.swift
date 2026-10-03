import SwiftUI

struct EmptySampleDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> SampleDataPreviewContext {
        try PreviewSampleData.makeContext(includesSampleData: false)
    }

    func body(
        content: Content,
        context: SampleDataPreviewContext
    ) -> some View {
        SampleDataPreviewHost(content: content, context: context)
    }
}
