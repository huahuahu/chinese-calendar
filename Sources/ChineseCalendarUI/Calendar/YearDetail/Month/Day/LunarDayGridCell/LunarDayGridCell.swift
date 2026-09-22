import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示在 LunarMonthGrid 的日期网格中，用于呈现单个农历日。
struct LunarDayGridCell: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let spacing: CGFloat = 6
        static let titleHorizontalPadding: CGFloat = 6
        static let titleVerticalPadding: CGFloat = 2
        static let padding: CGFloat = 10
        static let minimumHeight: CGFloat = 72
        static let cornerRadius: CGFloat = 18
        static let borderWidth: CGFloat = 1
        static let borderOpacity: Double = 0.08
    }

    let day: ChineseLunarDay
    let isSelected: Bool
    let isToday: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var differentiateWithoutColor
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            Text(dayTitle)
                .font(.headline)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, Constants.titleHorizontalPadding)
                .padding(.vertical, Constants.titleVerticalPadding)
                .foregroundStyle(state.titleForegroundColor)
                .background(state.titleBackgroundColor, in: Capsule())
                .overlay {
                    if showsTodayOutline {
                        Capsule()
                            .strokeBorder(Color.accentColor, lineWidth: Constants.borderWidth)
                    }
                }

            Text(daySubtitle)
                .font(.subheadline)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.secondary)

            Text(civilDateTitle)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.primary)
        .padding(Constants.padding)
        .frame(minHeight: Constants.minimumHeight, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(Color.primary.opacity(Constants.borderOpacity), lineWidth: Constants.borderWidth)
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
        LunarCalendarFormatting.daySubtitle(stemIndex: day.dayStemIndex, branchIndex: day.dayBranchIndex)
    }

    private var civilDateTitle: String {
        guard let julianDayNumber = day.calendarDay?.julianDayNumber else {
            return "-"
        }

        return LunarCalendarFormatting.civilDateTitle(
            julianDayNumber: julianDayNumber,
            locale: locale
        )
    }

    private var accessibilityLabel: String {
        let components: [String?] = [dayTitle, isToday ? "今天" : nil, "日干支", daySubtitle, civilDateTitle]
        return components
            .compactMap(\.self)
            .joined(separator: "，")
    }

    private var showsTodayOutline: Bool {
        differentiateWithoutColor && state == .today
    }
}
