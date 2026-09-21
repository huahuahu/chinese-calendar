import ChineseCalendarPersistence

struct ReignEraCardModel: Identifiable {
    let id: String
    let name: String
    let usageRangeText: String
    let durationText: String?
    let emperorName: String
    let emperorTitle: String?

    init(reignEra: ReignEra) {
        id = reignEra.id
        name = reignEra.name
        usageRangeText = HistoryDateRangeFormatter.usageRange(
            start: reignEra.startDate,
            exclusiveEnd: reignEra.endDate
        )
        durationText = HistoryDateRangeFormatter.usageDurationYears(
            start: reignEra.startDate,
            exclusiveEnd: reignEra.endDate
        ).map { "\($0) 年" }
        emperorName = reignEra.emperor.personalName ?? reignEra.emperor.displayName
        emperorTitle = reignEra.emperor.templeName ?? reignEra.emperor.posthumousName
    }

    init(
        id: String,
        name: String,
        usageRangeText: String,
        durationText: String?,
        emperorName: String,
        emperorTitle: String?
    ) {
        self.id = id
        self.name = name
        self.usageRangeText = usageRangeText
        self.durationText = durationText
        self.emperorName = emperorName
        self.emperorTitle = emperorTitle
    }

    var emperorText: String {
        if let emperorTitle {
            "\(emperorName) · \(emperorTitle)"
        } else {
            emperorName
        }
    }

    var accessibilityLabel: String {
        [name, usageRangeText, durationText, emperorText]
            .compactMap(\.self)
            .joined(separator: "，")
    }
}
