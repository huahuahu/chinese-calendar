import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 朝代资料枢纽；通过稳定 ID 保留进入本页的正统时期上下文。
struct DynastyDetailView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let factCardSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 18
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
            dynastyOverviewPage(dynasty: dynasty, period: period)
        } else {
            missingDynastyState
        }
    }

    private func dynastyOverviewPage(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        ScrollView {
            factCardList(dynasty: dynasty, period: period)
        }
        .navigationTitle(dynasty.shortName ?? dynasty.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func factCardList(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> some View {
        LazyVStack(alignment: .leading, spacing: Constants.factCardSpacing) {
            ForEach(factCardModels(dynasty: dynasty, period: period)) { model in
                DynastyFactCard(model: model)
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.contentVerticalPadding)
        .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
    }

    private var missingDynastyState: some View {
        ContentUnavailableView {
            Label(CalendarStringKey.History.DynastyDetail.Unavailable.title, systemSymbol: .buildingColumns)
        } description: {
            Text(CalendarStringKey.History.DynastyDetail.Unavailable.periodMessage)
        }
    }

    private func factCardModels(
        dynasty: Dynasty,
        period: OrthodoxPeriod
    ) -> [DynastyFactCardModel] {
        let dynastyName = dynasty.shortName ?? dynasty.name
        let emperorCount = dynasty.emperors.count
        let reignEraCount = dynasty.emperors.reduce(0) { count, emperor in
            count + emperor.reignEras.count
        }
        let spanYears = HistoryDateRangeFormatter.dynastySpanYears(
            start: period.startBoundary?.date,
            end: period.endBoundary?.date
        )

        return [
            DynastyFactCardModel(
                value: "\(emperorCount)",
                unit: String(localized: CalendarStringKey.History.DynastyDetail.Fact.emperorUnit),
                accessibilityLabel: String(localized: CalendarStringKey.History.DynastyDetail.Fact
                    .emperorsAccessibilityLabel(
                        dynasty: dynastyName,
                        count: emperorCount
                    )),
                destination: .emperorList(dynastyID: dynasty.id)
            ),
            DynastyFactCardModel(
                value: "\(reignEraCount)",
                unit: String(localized: CalendarStringKey.History.DynastyDetail.Fact.reignEraUnit),
                accessibilityLabel: String(localized: CalendarStringKey.History.DynastyDetail.Fact
                    .reignErasAccessibilityLabel(
                        dynasty: dynastyName,
                        count: reignEraCount
                    )),
                destination: .reignEraList(dynastyID: dynasty.id)
            ),
            DynastyFactCardModel(
                value: spanYears
                    .map(String.init) ?? String(localized: CalendarStringKey.History.DynastySpan.unavailableDuration),
                unit: spanYears == nil ? "" : String(localized: CalendarStringKey.History.DynastyDetail.Fact.yearUnit),
                accessibilityLabel: spanYears.map {
                    String(localized: CalendarStringKey.History.DynastyDetail.Fact.spanAccessibilityLabel(
                        dynasty: dynastyName,
                        years: $0
                    ))
                } ??
                    String(localized: CalendarStringKey.History.DynastyDetail.Fact
                        .unknownSpanAccessibilityLabel(dynasty: dynastyName)),
                destination: .dynastySpan(orthodoxPeriodID: period.id)
            )
        ]
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        DynastyDetailView(orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID)
    }
}
