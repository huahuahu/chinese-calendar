import ChineseCalendarLocalization
import ChineseCalendarPersistence

struct DynastyCardModel: Identifiable {
    let id: String
    let dynastyName: String
    let boundaryText: String
    let statisticsText: String?
    let unavailableText: String?

    init(period: OrthodoxPeriod) {
        id = period.id
        dynastyName = period.dynasty?.shortName ?? period.dynasty?.name ?? period.segmentName
        boundaryText = HistoryDateRangeFormatter.orthodoxPeriodRange(
            start: period.startBoundary?.date,
            end: period.endBoundary?.date
        )

        if let dynasty = period.dynasty {
            let emperorCount = dynasty.emperors.count
            let reignEraCount = dynasty.emperors.reduce(0) { count, emperor in
                count + emperor.reignEras.count
            }
            statisticsText = String(localized: CalendarStringKey.History.DynastyCard.statistics(
                emperorCount: emperorCount,
                eraCount: reignEraCount
            ))
            unavailableText = nil
        } else {
            statisticsText = nil
            unavailableText = String(localized: CalendarStringKey.History.DynastyCard.unavailable)
        }
    }

    init(
        id: String,
        dynastyName: String,
        boundaryText: String,
        statisticsText: String?,
        unavailableText: String? = nil
    ) {
        self.id = id
        self.dynastyName = dynastyName
        self.boundaryText = boundaryText
        self.statisticsText = statisticsText
        self.unavailableText = unavailableText
    }

    var accessibilityLabel: String {
        CalendarStringKey.Common.List.names([dynastyName, boundaryText, statisticsText, unavailableText]
            .compactMap(\.self))
    }
}
