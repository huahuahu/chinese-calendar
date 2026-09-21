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
        .navigationTitle("朝代起讫")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func orthodoxTimelineSummary(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.summarySpacing) {
            Text("\(dynasty.shortName ?? dynasty.name) · 正统时间线")
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
            sectionEyebrow("边界对照")

            Text("朝代自称与正统期")
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
                sectionEyebrow("相关说明")

                Text("关键边界事件")
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
            Label("没有找到朝代起讫", systemSymbol: .buildingColumns)
        } description: {
            Text("对应的朝代或正统期记录不在当前 SwiftData store 中。")
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
        ).map { "国祚 \($0) 年" } ?? "国祚暂无"
    }
}

#Preview {
    NavigationStack {
        DynastySpanDetailView(orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID)
    }
    .modelContainer(HistoryPreviewData.container)
}
