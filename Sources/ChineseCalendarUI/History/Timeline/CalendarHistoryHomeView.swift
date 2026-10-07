import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 朝代 Tab 根页面，按默认正统传统列出每一段正统时期。
struct CalendarHistoryHomeView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let listSpacing: CGFloat = 0
        static let horizontalPadding: CGFloat = 18
        static let introductionBottomPadding: CGFloat = 20
        static let sectionHeaderSpacing: CGFloat = 12
        static let sectionHeaderMinimumSpacerLength: CGFloat = 12
        static let sectionHeaderHorizontalInset: CGFloat = 2
        static let sectionHeaderBottomPadding: CGFloat = 10
        static let timelineStrokeWidth: CGFloat = 1
        static let timelineVerticalInset: CGFloat = 36
        static let timelineHorizontalOffset: CGFloat = 15
        static let contentVerticalPadding: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
    }

    @Query private var periods: [OrthodoxPeriod]

    init() {
        let traditionID = HistoryConfiguration.defaultOrthodoxTraditionID
        _periods = Query(
            filter: #Predicate<OrthodoxPeriod> { period in
                period.tradition?.id == traditionID
            },
            sort: \OrthodoxPeriod.sequenceIndex
        )
    }

    var body: some View {
        ScrollView {
            timelineContent
        }
        .navigationTitle(CalendarStringKey.History.Timeline.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private var timelineContent: some View {
        LazyVStack(alignment: .leading, spacing: Constants.listSpacing) {
            timelineIntroduction
            timelineSection
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.contentVerticalPadding)
        .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
    }

    private var timelineIntroduction: some View {
        Text(CalendarStringKey.History.Timeline.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, Constants.introductionBottomPadding)
    }

    @ViewBuilder
    private var timelineSection: some View {
        if periods.isEmpty {
            emptyTimelineState
        } else {
            timelineSectionHeader
            dynastyTimeline
        }
    }

    private var emptyTimelineState: some View {
        ContentUnavailableView {
            Label(CalendarStringKey.History.Timeline.Empty.title, systemSymbol: .timelineSelection)
        } description: {
            Text(CalendarStringKey.History.Timeline.Empty.message)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var timelineSectionHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.sectionHeaderSpacing) {
            Text(CalendarStringKey.History.Timeline.listTitle)
                .font(.headline)
                .bold()

            Spacer(minLength: Constants.sectionHeaderMinimumSpacerLength)

            Text(CalendarStringKey.History.Timeline.sortLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Constants.sectionHeaderHorizontalInset)
        .padding(.bottom, Constants.sectionHeaderBottomPadding)
    }

    private var dynastyTimeline: some View {
        LazyVStack(spacing: Constants.listSpacing) {
            ForEach(periods, id: \.id, content: dynastyTimelineRow)
        }
        .background(alignment: .leading) {
            Rectangle()
                .fill(.quaternary)
                .frame(width: Constants.timelineStrokeWidth)
                .padding(.vertical, Constants.timelineVerticalInset)
                .offset(x: Constants.timelineHorizontalOffset)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func dynastyTimelineRow(_ period: OrthodoxPeriod) -> some View {
        let model = DynastyCardModel(period: period)
        if period.dynasty != nil {
            NavigationLink(
                value: CalendarDestination.dynasty(orthodoxPeriodID: period.id)
            ) {
                DynastyCard(model: model, showsDisclosureIndicator: true)
            }
            .buttonStyle(HistoryPressButtonStyle())
        } else {
            DynastyCard(model: model, showsDisclosureIndicator: false)
        }
    }
}

#Preview("示例数据", traits: .sampleData) {
    NavigationStack {
        CalendarHistoryHomeView()
    }
}

#Preview("空状态", traits: .emptySampleData) {
    NavigationStack {
        CalendarHistoryHomeView()
    }
}
