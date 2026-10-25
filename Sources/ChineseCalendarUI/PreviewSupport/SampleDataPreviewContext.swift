import ChineseCalendarPersistence
import Foundation
import SwiftData

/// Preview 系统缓存并复用的只读依赖；可变页面状态由每个 Preview 的 Host 单独创建。
struct SampleDataPreviewContext {
    let modelContainer: ModelContainer
    let selection: CalendarSelectionValue?
    let today: Date
    var contentLevel: ChineseCalendarSeedStoreContentLevel = .full

    var selectedDayIndex: Int? {
        guard case let .day(index) = selection else { return nil }
        return index
    }
}
