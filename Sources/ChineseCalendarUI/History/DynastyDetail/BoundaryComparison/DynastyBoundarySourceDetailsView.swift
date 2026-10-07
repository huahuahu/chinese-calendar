import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 由边界比较卡片弹出，用于展示朝代边界的原始来源说明。
struct DynastyBoundarySourceDetailsView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sourceSpacing: CGFloat = 10
        static let disclosureTopPadding: CGFloat = 8
        static let detailSpacing: CGFloat = 3
    }

    let claimedStartDate: ChineseDateExpression
    let orthodoxStartDate: ChineseDateExpression?
    let claimedEndDate: ChineseDateExpression
    let orthodoxEndDate: ChineseDateExpression?
    let note: String?

    var body: some View {
        DisclosureGroup {
            sourceDetails
        } label: {
            Label(CalendarStringKey.History.Boundary.Source.title, systemSymbol: .infoCircle)
                .font(.callout)
        }
    }

    private var sourceDetails: some View {
        VStack(alignment: .leading, spacing: Constants.sourceSpacing) {
            sourceDetailRow(
                String(localized: CalendarStringKey.History.Boundary.Source.claimedStart),
                date: claimedStartDate
            )
            sourceDetailRow(
                String(localized: CalendarStringKey.History.Boundary.Source.orthodoxStart),
                date: orthodoxStartDate
            )
            sourceDetailRow(
                String(localized: CalendarStringKey.History.Boundary.Source.claimedEnd),
                date: claimedEndDate
            )
            sourceDetailRow(
                String(localized: CalendarStringKey.History.Boundary.Source.orthodoxEnd),
                date: orthodoxEndDate
            )

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, Constants.disclosureTopPadding)
    }

    private func sourceDetailRow(_ title: String, date: ChineseDateExpression?) -> some View {
        VStack(alignment: .leading, spacing: Constants.detailSpacing) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)

            Text(detailText(for: date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func detailText(for date: ChineseDateExpression?) -> String {
        guard let date else {
            return String(localized: CalendarStringKey.History.Boundary.unknown)
        }

        let precision = date.index.map {
            String(localized: CalendarStringKey.Common.DatePrecision.indexed(
                precision: precisionText(for: date), index: $0
            ))
        } ?? precisionText(for: date)
        if let note = date.note {
            return String(localized: CalendarStringKey.History.Boundary.Source.notedDetail(
                precision: precision, source: date.sourceText, note: note
            ))
        }
        return String(localized: CalendarStringKey.History.Boundary.Source.detail(
            precision: precision, source: date.sourceText
        ))
    }

    private func precisionText(for date: ChineseDateExpression) -> String {
        switch date.precision {
        case .year:
            String(localized: CalendarStringKey.Common.DatePrecision.year)
        case .month:
            String(localized: CalendarStringKey.Common.DatePrecision.month)
        case .day:
            String(localized: CalendarStringKey.Common.DatePrecision.day)
        case .range:
            String(localized: CalendarStringKey.Common.DatePrecision.range)
        case .unknown:
            String(localized: CalendarStringKey.Common.DatePrecision.unknown)
        }
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundarySourceDetailsView(
        claimedStartDate: sample.dynasty.claimedStartDate,
        orthodoxStartDate: sample.period.startBoundary?.date,
        claimedEndDate: sample.dynasty.claimedEndDate,
        orthodoxEndDate: sample.period.endBoundary?.date,
        note: sample.period.note
    )
    .padding()
}
