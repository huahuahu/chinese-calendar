import ChineseCalendarCore
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

struct LunarMonthGrid: View {
    let month: ChineseLunarMonth
    @Environment(\.calendarStoreContentLevel) private var storeContentLevel
    @Query private var days: [ChineseLunarDay]

    init(month: ChineseLunarMonth) {
        self.month = month

        let lunarMonthIndex = month.lunarMonthIndex
        _days = Query(
            filter: #Predicate<ChineseLunarDay> { day in
                day.lunarMonthIndex == lunarMonthIndex
            },
            sort: \ChineseLunarDay.dayNumberInMonth
        )
    }

    private var periods: [LunarTenDayPeriod] {
        LunarTenDayPeriod.makePeriods(from: days)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月日期")
                .font(.title2)
                .bold()

            if periods.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(emptyStateTitle, systemSymbol: emptyStateSystemSymbol)
                    },
                    description: {
                        Text(emptyStateDescription)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(periods) { period in
                            LunarTenDayPeriodRow(period: period)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var emptyStateTitle: String {
        switch storeContentLevel {
        case .base:
            "完整日期数据尚未下载"
        case .full:
            "没有日期数据"
        }
    }

    private var emptyStateSystemSymbol: SFSymbol {
        switch storeContentLevel {
        case .base:
            .arrowDownCircle
        case .full:
            .calendarBadgeExclamationmark
        }
    }

    private var emptyStateDescription: String {
        switch storeContentLevel {
        case .base:
            "当前内置数据只包含年份和月份；下载完整数据后会显示每日干支和对应公历日期。"
        case .full:
            "这个月份暂时没有可显示的日级记录。"
        }
    }
}

private struct LunarTenDayPeriod: Identifiable {
    let id: Int
    let title: String
    let days: [ChineseLunarDay]

    static func makePeriods(from days: [ChineseLunarDay]) -> [Self] {
        [
            Self(id: 0, title: "上旬", days: days.filter { (1 ... 10).contains($0.dayNumberInMonth) }),
            Self(id: 1, title: "中旬", days: days.filter { (11 ... 20).contains($0.dayNumberInMonth) }),
            Self(id: 2, title: "下旬", days: days.filter { (21 ... 30).contains($0.dayNumberInMonth) })
        ]
        .filter { !$0.days.isEmpty }
    }
}

private struct LunarTenDayPeriodRow: View {
    let period: LunarTenDayPeriod

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(period.title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .topLeading)
                .frame(minHeight: 88, alignment: .topLeading)

            ForEach(period.days, id: \.dayIndex) { day in
                LunarDayCell(day: day)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LunarDayCell: View {
    let day: ChineseLunarDay

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LunarCalendarFormatting.dayTitle(dayNumberInMonth: day.dayNumberInMonth))
                .font(.headline)
            Text(LunarCalendarFormatting.daySubtitle(
                stemIndex: day.dayStemIndex,
                branchIndex: day.dayBranchIndex
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Text(civilDateTitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(width: 96, alignment: .topLeading)
        .frame(minHeight: 88, alignment: .topLeading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var civilDateTitle: String {
        guard let civilDate = day.calendarDay?.civilDate else {
            return "-"
        }

        return LunarCalendarFormatting.civilDateTitle(
            year: civilDate.year,
            month: civilDate.month,
            dayOfMonth: civilDate.dayOfMonth,
            isJulianCalendar: civilDate.calendarStyle == .julian
        )
    }
}
