import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 根据唯一选中日推导当前农历月和农历年，并组合日历页面的四个区域。
struct CalendarPageView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sectionSpacing: CGFloat = 16
        static let headerCornerRadius: CGFloat = 28
        static let unavailableMinimumHeight: CGFloat = 320
    }

    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Query private var selectedDays: [ChineseLunarDay]

    init(selectedDayIndex: Int?) {
        let queryDayIndex = selectedDayIndex ?? Int.min
        _selectedDays = Query(
            filter: #Predicate<ChineseLunarDay> { day in
                day.dayIndex == queryDayIndex
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                if let selectedDay, let selectedMonth = selectedDay.chineseLunarMonth {
                    YearMonthHeader(month: selectedMonth)
                        .padding()
                        .background(
                            .background.secondary,
                            in: RoundedRectangle(cornerRadius: Constants.headerCornerRadius)
                        )

                    LunarDayGrid(month: selectedMonth)

                    SelectedLunarDayDetail(day: selectedDay)
                } else {
                    unavailableContent
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.calendarSystemBackground)
        .navigationTitle("日历")
    }

    private var selectedDay: ChineseLunarDay? {
        selectedDays.first
    }

    private var unavailableContent: some View {
        ContentUnavailableView {
            Label(unavailableTitle, systemSymbol: unavailableSystemSymbol)
        } description: {
            Text(unavailableDescription)
        }
        .frame(maxWidth: .infinity, minHeight: Constants.unavailableMinimumHeight)
    }

    private var unavailableTitle: String {
        switch storeContentLevel {
        case .base:
            "需要完整日期数据"
        case .full:
            "没有找到日期"
        }
    }

    private var unavailableSystemSymbol: SFSymbol {
        switch storeContentLevel {
        case .base:
            .arrowDownCircle
        case .full:
            .calendarBadgeExclamationmark
        }
    }

    private var unavailableDescription: String {
        switch storeContentLevel {
        case .base:
            "当前内置数据只有年份和月份。请先下载完整日期数据，再浏览日历。"
        case .full:
            "当前导航地址无法解析为一个具体农历日。"
        }
    }
}

private struct CalendarPagePreviewContent: View {
    @Environment(CalendarSelection.self) private var selection

    var body: some View {
        CalendarPageView(selectedDayIndex: selection.selectedDayIndex)
    }
}

#Preview("完整日历", traits: .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

// 核对应用的 TabView 与导航层级；Duo 系统竖栏仍需结合模拟器中的实际运行验证。
#Preview("完整日历 · 应用导航", traits: .sampleData) {
    CalendarHomeView()
}

#Preview("有可能空白", traits: .emptySampleData) {
    NavigationStack {
        CalendarPageView(selectedDayIndex: nil)
    }
}

#Preview("有可能空白 · 未下载完整日期", traits: .sampleData) {
    NavigationStack {
        CalendarPageView(selectedDayIndex: nil)
            .environment(\.calendarStoreContentLevel, .base)
    }
}

#Preview("有可能空白 · 日期不存在", traits: .sampleData) {
    NavigationStack {
        CalendarPageView(selectedDayIndex: -1)
    }
}

// 点击下个月进入公元 1 年；反向场景点击上个月回到公元前 1 年。
#Preview("公元前 1 年 → 公元 1 年", traits: .sampleData(.beforeCommonEra)) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

#Preview("公元 1 年 → 公元前 1 年", traits: .sampleData(.commonEra)) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

#Preview("公元前 221 年 · 后九月", traits: .sampleData(.postNinthMonth)) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

// 固定尺寸仅用于回归预览；生产页面始终接受当前窗口提供的宽度。
#Preview("窄屏 · 375×812", traits: .fixedLayout(width: 375, height: 812), .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

#Preview("窄屏 · 辅助功能 5", traits: .fixedLayout(width: 375, height: 812), .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("宽屏竖向 · 1024×1366", traits: .fixedLayout(width: 1024, height: 1366), .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

#Preview("宽屏横向 · 1366×1024", traits: .fixedLayout(width: 1366, height: 1024), .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
}

#Preview("分屏宽度 · 辅助功能 5", traits: .fixedLayout(width: 507, height: 1024), .sampleData) {
    NavigationStack {
        CalendarPagePreviewContent()
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("窄屏空状态 · 辅助功能 5", traits: .fixedLayout(width: 375, height: 812), .emptySampleData) {
    NavigationStack {
        CalendarPageView(selectedDayIndex: nil)
            .environment(\.calendarStoreContentLevel, .base)
    }
    .environment(\.dynamicTypeSize, .accessibility5)
}
