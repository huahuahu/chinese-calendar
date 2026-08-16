import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示在 LunarMonthGrid 的日期网格中，用于呈现单个农历日。
struct LunarDayGridCell: View {
    let day: ChineseLunarDay
    let isSelected: Bool
    let isToday: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dayTitle)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .foregroundStyle(state.titleForegroundColor)
                .background(state.titleBackgroundColor, in: Capsule())
                .overlay {
                    if showsTodayOutline {
                        Capsule()
                            .strokeBorder(Color.accentColor, lineWidth: 1)
                    }
                }

            Text(daySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(civilDateTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var state: LunarDayGridCellState {
        LunarDayGridCellState(isToday: isToday, isSelected: isSelected)
    }

    private var dayTitle: String {
        LunarCalendarFormatting.dayTitle(dayNumberInMonth: day.dayNumberInMonth)
    }

    private var daySubtitle: String {
        "\(LunarCalendarFormatting.daySubtitle(stemIndex: day.dayStemIndex, branchIndex: day.dayBranchIndex))日"
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

    private var accessibilityLabel: String {
        [dayTitle, isToday ? "今天" : nil, daySubtitle, civilDateTitle]
            .compactMap(\.self)
            .joined(separator: "，")
    }

    private var showsTodayOutline: Bool {
        differentiateWithoutColor && state == .today
    }
}
