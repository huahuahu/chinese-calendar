import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 对照朝代自称边界与进入本页的正统期，并展示结构化边界事件。
struct DynastySpanDetailView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sectionSpacing: CGFloat = 26
        static let horizontalPadding: CGFloat = 18
        static let summarySpacing: CGFloat = 9
        static let summaryHorizontalSpacing: CGFloat = 9
        static let summaryMarkerSize: CGFloat = 3
        static let compactSummarySpacing: CGFloat = 5
        static let summaryBottomPadding: CGFloat = 18
        static let separatorHeight: CGFloat = 1
        static let sectionHeadingSpacing: CGFloat = 10
        static let contentVerticalPadding: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
    }

    @Query private var periods: [OrthodoxPeriod]

    init(orthodoxPeriodID: String) {
        let orthodoxPeriodID = orthodoxPeriodID
        _periods = Query(
            filter: #Predicate<OrthodoxPeriod> { period in
                period.id == orthodoxPeriodID
            }
        )
    }

    var body: some View {
        pageContent
    }

    @ViewBuilder
    private var pageContent: some View {
        if let period = periods.first, let dynasty = period.dynasty {
            dynastySpanPage(dynasty: dynasty, period: period)
        } else {
            missingDynastySpanState
        }
    }

    private func dynastySpanPage(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        let events = HistoryBoundaryEventRepository.events(for: period, dynasty: dynasty)

        return ScrollView {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                orthodoxTimelineSummary(dynasty: dynasty, period: period)
                boundaryComparisonSection(dynasty: dynasty, period: period)
                boundaryEventsSection(events)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.contentVerticalPadding)
            .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
        }
        .navigationTitle(CalendarStringKey.History.DynastySpan.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func orthodoxTimelineSummary(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.summarySpacing) {
            Text(String(localized: CalendarStringKey.History.DynastySpan
                    .subtitle(dynasty: dynasty.shortName ?? dynasty.name)))
                .font(.caption)
                .bold()
                .foregroundStyle(.tint)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Constants.summaryHorizontalSpacing) {
                    orthodoxRangeText(period)
                    summaryMarker
                    dynastySpanText(period)
                }

                VStack(alignment: .leading, spacing: Constants.compactSummarySpacing) {
                    orthodoxRangeText(period)
                    dynastySpanText(period)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Constants.summaryBottomPadding)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: Constants.separatorHeight)
        }
        .accessibilityElement(children: .combine)
    }

    private func orthodoxRangeText(_ period: OrthodoxPeriod) -> some View {
        Text(orthodoxRange(period))
            .font(.title2.monospacedDigit())
            .fontDesign(.serif)
            .bold()
    }

    private var summaryMarker: some View {
        Circle()
            .fill(.secondary)
            .frame(
                width: Constants.summaryMarkerSize,
                height: Constants.summaryMarkerSize
            )
            .accessibilityHidden(true)
    }

    private func dynastySpanText(_ period: OrthodoxPeriod) -> some View {
        Text(spanText(period))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func boundaryComparisonSection(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.sectionHeadingSpacing) {
            sectionEyebrow(String(localized: CalendarStringKey.History.DynastySpan.boundaryEyebrow))

            Text(CalendarStringKey.History.DynastySpan.boundaryTitle)
                .font(.title2)
                .bold()

            DynastyBoundarySummaryCard(
                claimedRange: HistoryDateRangeFormatter.claimedDynastyRange(
                    start: dynasty.claimedStartDate,
                    end: dynasty.claimedEndDate
                ),
                orthodoxRange: orthodoxRange(period)
            )
        }
    }

    @ViewBuilder
    private func boundaryEventsSection(_ events: [HistoryBoundaryEvent]) -> some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: Constants.sectionHeadingSpacing) {
                sectionEyebrow(String(localized: CalendarStringKey.History.DynastySpan.eventsEyebrow))

                Text(CalendarStringKey.History.DynastySpan.eventsTitle)
                    .font(.title2)
                    .bold()

                DynastyBoundaryEventTimeline(events: events)
            }
        }
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(.tint)
    }

    private var missingDynastySpanState: some View {
        ContentUnavailableView {
            Label(CalendarStringKey.History.DynastySpan.Unavailable.title, systemSymbol: .buildingColumns)
        } description: {
            Text(CalendarStringKey.History.DynastyDetail.Unavailable.periodMessage)
        }
    }

    private func orthodoxRange(_ period: OrthodoxPeriod) -> String {
        HistoryDateRangeFormatter.orthodoxPeriodRange(
            start: period.startBoundary?.date,
            end: period.endBoundary?.date
        )
    }

    private func spanText(_ period: OrthodoxPeriod) -> String {
        HistoryDateRangeFormatter.dynastySpanYears(
            start: period.startBoundary?.date,
            end: period.endBoundary?.date
        )
        .map { String(localized: CalendarStringKey.History.DynastySpan.duration(years: $0)) } ??
        String(localized: CalendarStringKey.History.DynastySpan.unavailableDuration)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        DynastySpanDetailView(orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID)
    }
}
