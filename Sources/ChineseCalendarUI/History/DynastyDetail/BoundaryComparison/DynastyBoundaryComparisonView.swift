import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SwiftUI

/// 显示在 DynastyDetailView 中，用于比较朝代各正统时期的起止边界。
struct DynastyBoundaryComparisonView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 12
        static let headingSpacing: CGFloat = 6
    }

    let dynasty: Dynasty
    let orthodoxPeriods: [OrthodoxPeriod]

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            sectionHeading
            comparisonCards
        }
    }

    private var sectionHeading: some View {
        VStack(alignment: .leading, spacing: Constants.headingSpacing) {
            Text(CalendarStringKey.History.Boundary.Comparison.title)
                .font(.title2)
                .bold()

            Text(CalendarStringKey.History.Boundary.Comparison.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var comparisonCards: some View {
        if orthodoxPeriods.isEmpty {
            DynastyBoundaryComparisonCard(
                title: String(localized: CalendarStringKey.History.Boundary.period),
                traditionName: nil,
                claimedStartDate: dynasty.claimedStartDate,
                orthodoxStartDate: nil,
                claimedEndDate: dynasty.claimedEndDate,
                orthodoxEndDate: nil,
                startDifferenceText: nil,
                endDifferenceText: nil,
                note: String(localized: CalendarStringKey.History.Boundary.Comparison.missingMessage)
            )
        } else {
            ForEach(orthodoxPeriods, id: \.id) { period in
                comparisonCard(for: period)
            }
        }
    }

    private func comparisonCard(for period: OrthodoxPeriod) -> some View {
        DynastyBoundaryComparisonCard(
            title: periodTitle(for: period),
            traditionName: period.tradition?.name,
            claimedStartDate: dynasty.claimedStartDate,
            orthodoxStartDate: period.startBoundary?.date,
            claimedEndDate: dynasty.claimedEndDate,
            orthodoxEndDate: period.endBoundary?.date,
            startDifferenceText: differenceText(
                claimed: dynasty.claimedStartDate,
                orthodox: period.startBoundary?.date
            ),
            endDifferenceText: differenceText(
                claimed: dynasty.claimedEndDate,
                orthodox: period.endBoundary?.date
            ),
            note: period.note
        )
    }

    private func periodTitle(for period: OrthodoxPeriod) -> String {
        if period.segmentName == dynasty.name || period.segmentName == dynasty.shortName {
            return String(localized: CalendarStringKey.History.Boundary.period)
        }

        return String(localized: CalendarStringKey.History.Boundary.namedPeriod(name: period.segmentName))
    }

    private func differenceText(
        claimed: ChineseDateExpression,
        orthodox: ChineseDateExpression?
    ) -> String? {
        guard let orthodox else {
            return nil
        }

        guard claimed.precision == orthodox.precision else {
            return String(localized: CalendarStringKey.History.Boundary.Comparison.differentPrecision)
        }

        guard let claimedIndex = claimed.index, let orthodoxIndex = orthodox.index else {
            return claimed.sourceText == orthodox
                .sourceText ? String(localized: CalendarStringKey.History.Boundary.Comparison.sameSource) :
                String(localized: CalendarStringKey.History.Boundary.Comparison.differentSource)
        }

        let difference = orthodoxIndex - claimedIndex

        guard difference != 0 else {
            return claimed
                .precision == .year ? String(localized: CalendarStringKey.History.Boundary.Comparison.sameYear) :
                String(localized: CalendarStringKey.History.Boundary.Comparison.sameBoundary)
        }

        guard claimed.precision == .year else {
            return String(localized: CalendarStringKey.History.Boundary.Comparison.differentBoundary)
        }

        return difference > 0 ?
            String(localized: CalendarStringKey.History.Boundary.Comparison.later(years: difference)) :
            String(localized: CalendarStringKey.History.Boundary.Comparison.earlier(years: abs(difference)))
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundaryComparisonView(
        dynasty: sample.dynasty,
        orthodoxPeriods: [sample.period]
    )
    .padding()
}
