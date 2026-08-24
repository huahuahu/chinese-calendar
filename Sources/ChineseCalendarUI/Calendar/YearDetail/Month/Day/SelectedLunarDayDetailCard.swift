import ChineseCalendarCore
import ChineseCalendarPersistence
import SwiftUI

/// 显示在 LunarMonthGrid 中，用于展开说明当前选中的农历日。
struct SelectedLunarDayDetailCard: View {
    let day: ChineseLunarDay
    let month: ChineseLunarMonth
    let contentLevel: ChineseCalendarSeedStoreContentLevel

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
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
                    .frame(width: 54, height: 54)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                CalendarFactTile(title: "农历表达", value: lunarExpression)
                CalendarFactTile(title: "日干支", value: dayStemBranch)
                CalendarFactTile(title: civilDateFactTitle, value: civilDateValue)
                CalendarFactTile(title: "数据层级", value: contentLevelTitle)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .contain)
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 10)]
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
        "\(LunarMonthDisplay.title(for: month))\(dayTitle)"
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
