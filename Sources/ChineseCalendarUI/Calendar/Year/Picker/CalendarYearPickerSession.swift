import Foundation
import SwiftData

/// 一次年份选择携带的发起页上下文；呈现状态只保存在 Router 节点中。
@MainActor
struct CalendarYearPickerSession: Identifiable {
    let id = UUID()
    let selection: CalendarSelection
    let modelContext: ModelContext
    let selectYear: (Int) -> Void
}
