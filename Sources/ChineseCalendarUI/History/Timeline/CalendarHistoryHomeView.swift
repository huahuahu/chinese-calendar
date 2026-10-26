import NavigationCore
import SwiftUI

/// 完整历史容器保持稳定，数据库更换只重建内部查询内容。
struct CalendarHistoryHomeView: View {
    var stack: NavigationStackID<CalendarTab> = .primary
    @Environment(CalendarPresentationContext.self) private var presentation

    var body: some View {
        let navigation = presentation.context(for: stack)
        CalendarHistoryContainer(stack: stack, navigation: navigation)
            .id(ObjectIdentifier(navigation))
    }
}

#Preview("朝代时间线 · 浅色", traits: .sampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
        .preferredColorScheme(.light)
}

#Preview("朝代时间线 · 深色", traits: .sampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
        .preferredColorScheme(.dark)
}

#Preview("朝代时间线 · 辅助功能字号", traits: .sampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("空时间线", traits: .emptySampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
}
