import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

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
                .foregroundStyle(isSelected ? Color.white.opacity(0.82) : Color.secondary)

            Text(civilDateTitle)
                .font(.subheadline)
                .foregroundStyle(isSelected ? Color.white.opacity(0.66) : Color.secondary)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.accentColor)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isToday && !isSelected ? Color.accentColor : Color.primary.opacity(0.08))
        }
        .accessibilityElement(children: .combine)
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
}
