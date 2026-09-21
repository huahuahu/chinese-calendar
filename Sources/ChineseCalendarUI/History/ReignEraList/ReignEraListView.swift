import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 按 ReignEra.sequenceIndex 展示一个朝代的完整年号时间线。
struct ReignEraListView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let listSpacing: CGFloat = 0
        static let horizontalPadding: CGFloat = 18
        static let summaryHorizontalInset: CGFloat = 2
        static let summaryBottomPadding: CGFloat = 12
        static let separatorHeight: CGFloat = 1
        static let timelineStrokeWidth: CGFloat = 1
        static let timelineVerticalInset: CGFloat = 41
        static let timelineHorizontalOffset: CGFloat = 9
        static let contentVerticalPadding: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
    }

    @Query private var dynasties: [Dynasty]
    @Query private var periods: [OrthodoxPeriod]
    @Query private var reignEras: [ReignEra]

    init(dynastyID: String) {
        let dynastyID = dynastyID
        let traditionID = HistoryConfiguration.defaultOrthodoxTraditionID
        _dynasties = Query(
            filter: #Predicate<Dynasty> { dynasty in
                dynasty.id == dynastyID
            }
        )
        _periods = Query(
            filter: #Predicate<OrthodoxPeriod> { period in
                period.traditionID == traditionID && period.dynastyID == dynastyID
            },
            sort: \OrthodoxPeriod.sequenceIndex
        )
        _reignEras = Query(
            filter: #Predicate<ReignEra> { reignEra in
                reignEra.emperor.dynasty.id == dynastyID
            },
            sort: \ReignEra.sequenceIndex
        )
    }

    var body: some View {
        pageContent
    }

    @ViewBuilder
    private var pageContent: some View {
        if dynasties.isEmpty {
            missingDynastyState
        } else {
            reignEraListPage
        }
    }

    private var reignEraListPage: some View {
        ScrollView {
            reignEraListContent
        }
        .navigationTitle("年号")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var reignEraListContent: some View {
        LazyVStack(alignment: .leading, spacing: Constants.listSpacing) {
            listSummary
            reignEraTimeline
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.contentVerticalPadding)
        .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
    }

    private var listSummary: some View {
        Text(summaryText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.summaryHorizontalInset)
            .padding(.bottom, Constants.summaryBottomPadding)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: Constants.separatorHeight)
            }
    }

    @ViewBuilder
    private var reignEraTimeline: some View {
        if reignEras.isEmpty {
            emptyReignEraListState
        } else {
            LazyVStack(spacing: Constants.listSpacing) {
                ForEach(reignEras, id: \.id, content: reignEraTimelineRow)
            }
            .background(alignment: .leading) {
                timelineRail
            }
        }
    }

    private func reignEraTimelineRow(_ reignEra: ReignEra) -> some View {
        NavigationLink(
            value: CalendarDestination.reignEra(reignEraID: reignEra.id)
        ) {
            ReignEraCard(model: ReignEraCardModel(reignEra: reignEra))
        }
        .buttonStyle(HistoryPressButtonStyle())
    }

    private var timelineRail: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: Constants.timelineStrokeWidth)
            .padding(.vertical, Constants.timelineVerticalInset)
            .offset(x: Constants.timelineHorizontalOffset)
            .accessibilityHidden(true)
    }

    private var emptyReignEraListState: some View {
        ContentUnavailableView {
            Label("没有年号资料", systemSymbol: .timelineSelection)
        } description: {
            Text("当前 store 中没有这个朝代的年号记录。")
        }
        .frame(maxWidth: .infinity)
    }

    private var missingDynastyState: some View {
        ContentUnavailableView {
            Label("没有找到朝代", systemSymbol: .buildingColumns)
        } description: {
            Text("这个朝代记录不在当前 SwiftData store 中。")
        }
    }

    private var summaryText: String {
        let boundaryText = periods.first.map {
            HistoryDateRangeFormatter.orthodoxPeriodRange(
                start: $0.startBoundary?.date,
                end: $0.endBoundary?.date
            )
        }
        return ["\(reignEras.count) 个年号", boundaryText]
            .compactMap(\.self)
            .joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        ReignEraListView(dynastyID: HistoryPreviewData.dynastyID)
    }
    .modelContainer(HistoryPreviewData.container)
}
