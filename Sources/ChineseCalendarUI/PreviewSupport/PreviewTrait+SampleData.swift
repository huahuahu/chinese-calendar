import SwiftUI

extension PreviewTrait where T == Preview.ViewTraits {
    /// 复用只读内存示例库，并为每个 Preview 隔离可变 Environment 模型。
    static var sampleData: Self {
        .modifier(SampleDataPreviewModifier())
    }

    /// 使用没有记录的内存库验证页面空状态。
    static var emptySampleData: Self {
        .modifier(EmptySampleDataPreviewModifier())
    }
}
