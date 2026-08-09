import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示在 LunarMonthGrid 的日期网格中，用于呈现单个农历日。
struct LunarDayGridCell: View {
    let day: ChineseLunarDay
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayTitle)
                    .font(.headline)

                Spacer(minLength: 4)

                if isToday {
                    Text("今日")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.white)
                        .background(isSelected ? Color.white.opacity(0.86) : Color.accentColor, in: Capsule())
                }
            }

            Text(daySubtitle)
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white.opacity(0.92) : Color.secondary)

            Text(civilDateTitle)
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white.opacity(0.84) : Color.secondary)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? Color.accentColor : Color.clear)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    private var borderColor: Color {
        if isSelected {
            return Color.white.opacity(0.72)
        }

        if isToday {
            return Color.accentColor
        }

        return Color.primary.opacity(0.08)
    }

    private var borderWidth: CGFloat {
        isSelected || isToday ? 1.5 : 1
    }
}
