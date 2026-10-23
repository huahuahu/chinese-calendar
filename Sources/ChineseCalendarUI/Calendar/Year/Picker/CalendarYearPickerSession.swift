import Observation
import SwiftData

/// 发起日历页面拥有的一次年份选择资源，不保存反向捕获页面的回调。
@MainActor
@Observable
final class CalendarYearPickerSession {
    let selection: CalendarSelection
    let modelContext: ModelContext
    let storeGeneration: Int
    private(set) var acceptsResult = true

    init(selection: CalendarSelection, modelContext: ModelContext, storeGeneration: Int) {
        self.selection = selection
        self.modelContext = modelContext
        self.storeGeneration = storeGeneration
    }

    func consumeResult() -> Bool {
        guard acceptsResult else { return false }
        acceptsResult = false
        return true
    }

    func invalidate() {
        acceptsResult = false
    }
}
