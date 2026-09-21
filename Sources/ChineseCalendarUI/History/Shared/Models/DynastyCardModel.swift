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
            statisticsText = "\(emperorCount) 位皇帝 · \(reignEraCount) 个年号"
            unavailableText = nil
        } else {
            statisticsText = nil
            unavailableText = "资料暂缺"
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
        [dynastyName, boundaryText, statisticsText, unavailableText]
            .compactMap(\.self)
            .joined(separator: "，")
    }
}
