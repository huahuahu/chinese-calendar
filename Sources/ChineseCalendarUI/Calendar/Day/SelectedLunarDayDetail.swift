import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示唯一选中日的详细信息；所属月份由日模型关系推导。
struct SelectedLunarDayDetail: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 16
        static let headerSpacing: CGFloat = 16
        static let titleSpacing: CGFloat = 6
        static let sealDimension: CGFloat = 54
        static let sealCornerRadius: CGFloat = 18
        static let factSpacing: CGFloat = 10
        static let factMinimumWidth: CGFloat = 140
        static let cornerRadius: CGFloat = 28
    }

    @Environment(\.calendarStoreContentLevel) private var contentLevel
    @Environment(\.locale) private var locale

    let day: ChineseLunarDay

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            HStack(alignment: .top, spacing: Constants.headerSpacing) {
                VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                    Text("选中日")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.tint)
                    Text(dayTitle)
                        .font(.largeTitle)
                        .bold()
                    Text(daySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(sealText)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: Constants.sealDimension, height: Constants.sealDimension)
                    .background(
                        Color.accentColor,
                        in: RoundedRectangle(cornerRadius: Constants.sealCornerRadius)
                    )
                    .accessibilityHidden(true)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: Constants.factSpacing) {
                CalendarFactTile(title: "农历表达", value: lunarExpression)
                CalendarFactTile(title: "日干支", value: dayStemBranch)
                CalendarFactTile(title: civilDateFactTitle, value: civilDateValue)
                CalendarFactTile(title: "数据层级", value: contentLevelTitle)
            }
        }
        .padding()
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cornerRadius)
        )
        .accessibilityElement(children: .contain)
    }

    private var month: ChineseLunarMonth? {
        day.chineseLunarMonth
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: Constants.factMinimumWidth),
                spacing: Constants.factSpacing
            )
        ]
    }

    private var dayTitle: String {
        LunarCalendarFormatting.dayTitle(dayNumberInMonth: day.dayNumberInMonth)
    }

    private var sealText: String {
        String(dayTitle.suffix(1))
    }

    private var dayStemBranch: String {
        LunarCalendarFormatting.daySubtitle(stemIndex: day.dayStemIndex, branchIndex: day.dayBranchIndex)
    }

    private var daySubtitle: String {
        "\(dayStemBranch)日 · \(fullCivilDateTitle)"
    }

    private var lunarExpression: String {
        guard let month else {
            return dayTitle
        }

        return "\(LunarMonthDisplay.title(for: month))\(dayTitle)"
    }

    private var civilDateFactTitle: String {
        "对应日期"
    }

    private var civilDateValue: String {
        fullCivilDateTitle
    }

    private var fullCivilDateTitle: String {
        guard let julianDayNumber = day.calendarDay?.julianDayNumber else {
            return "-"
        }

        return LunarCalendarFormatting.fullCivilDateTitle(
            julianDayNumber: julianDayNumber,
            locale: locale
        )
    }

    private var contentLevelTitle: String {
        switch contentLevel {
        case .base:
            "基础数据"
        case .full:
            "完整日期数据"
        }
    }
}

#Preview("完整关联数据") {
    let year = ChineseLunarYear(
        lunarYearNumber: 2026,
        yearStemIndex: 2,
        yearBranchIndex: 6
    )
    let month = ChineseLunarMonth(
        lunarMonthIndex: 3,
        lunarYearNumber: 2026,
        monthNumberInYear: 1,
        isLeapMonth: false,
        dayCount: 30,
        monthStemIndex: 2,
        monthBranchIndex: 2,
        chineseLunarYear: year
    )
    let day = ChineseLunarDay(
        dayIndex: 315,
        lunarMonthIndex: 3,
        dayNumberInMonth: 15,
        dayStemIndex: 4,
        dayBranchIndex: 2,
        calendarDay: CalendarDay(
            dayIndex: 315,
            julianDayNumber: 2_461_063
        ),
        chineseLunarMonth: month
    )

    NavigationStack {
        ScrollView {
            SelectedLunarDayDetail(day: day)
                .padding()
        }
        .navigationTitle("日历")
    }
    .environment(\.calendarStoreContentLevel, .full)
}

#Preview("有可能空白 · 关联数据缺失") {
    let day = ChineseLunarDay(
        dayIndex: 315,
        lunarMonthIndex: 3,
        dayNumberInMonth: 15,
        dayStemIndex: 4,
        dayBranchIndex: 2
    )

    NavigationStack {
        ScrollView {
            SelectedLunarDayDetail(day: day)
                .padding()
        }
        .navigationTitle("日历")
    }
    .environment(\.calendarStoreContentLevel, .base)
}
