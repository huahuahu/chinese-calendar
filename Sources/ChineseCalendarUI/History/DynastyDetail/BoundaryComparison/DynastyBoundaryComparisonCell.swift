import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SwiftUI

/// 显示在边界比较行中，用于呈现单一日期来源的边界值。
struct DynastyBoundaryComparisonCell: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 12
    }

    let date: ChineseDateExpression?

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            Text(primaryText)
                .font(.headline)
                .bold()

            Text(precisionText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var primaryText: String {
        guard let date else {
            return String(localized: CalendarStringKey.History.Boundary.unknown)
        }

        guard let index = date.index else {
            return date.sourceText
        }

        switch date.precision {
        case .year:
            return "\(index)"
        case .month:
            return String(localized: CalendarStringKey.History.Boundary.monthIndex(index: index))
        case .day:
            return String(localized: CalendarStringKey.History.Boundary.dayIndex(index: index))
        case .range, .unknown:
            return date.sourceText
        }
    }

    private var precisionText: String {
        guard let date else {
            return String(localized: CalendarStringKey.History.Boundary.missingData)
        }

        switch date.precision {
        case .year:
            return String(localized: CalendarStringKey.Common.DatePrecision.year)
        case .month:
            return String(localized: CalendarStringKey.Common.DatePrecision.month)
        case .day:
            return String(localized: CalendarStringKey.Common.DatePrecision.day)
        case .range:
            return String(localized: CalendarStringKey.Common.DatePrecision.range)
        case .unknown:
            return String(localized: CalendarStringKey.Common.DatePrecision.unknown)
        }
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundaryComparisonCell(date: sample.dynasty.claimedStartDate)
        .padding()
}
