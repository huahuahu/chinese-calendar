import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 根据唯一选中日推导当前农历月和农历年，并组合日历页面的四个区域。
struct LunarYearDetailView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sectionSpacing: CGFloat = 16
        static let headerCornerRadius: CGFloat = 28
        static let maximumContentWidth: CGFloat = 980
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
            .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
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
