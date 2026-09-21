import ChineseCalendarPersistence

enum HistoryBoundaryEventRepository {
    static func events(
        for period: OrthodoxPeriod,
        dynasty: Dynasty
    ) -> [HistoryBoundaryEvent] {
        let dynastyName = dynasty.shortName ?? dynasty.name
        var events: [HistoryBoundaryEvent] = []

        if let startDate = period.startBoundary?.date {
            events.append(HistoryBoundaryEvent(
                id: "\(period.id)-start",
                orthodoxPeriodID: period.id,
                dateExpressionID: startDate.id,
                timeText: HistoryDateRangeFormatter.boundaryText(startDate),
                title: "\(dynastyName)正统期开始",
                detail: "\(dynastyName)从这一边界进入当前正统时间线。",
                sequenceIndex: 0
            ))
        }

        if let endDate = period.endBoundary?.date {
            events.append(HistoryBoundaryEvent(
                id: "\(period.id)-end",
                orthodoxPeriodID: period.id,
                dateExpressionID: endDate.id,
                timeText: HistoryDateRangeFormatter.boundaryText(endDate),
                title: "\(dynastyName)正统期结束",
                detail: "当前正统时间线在这一边界结束\(dynastyName)时期。",
                sequenceIndex: 1
            ))
        }

        return events.sorted { ($0.sequenceIndex, $0.id) < ($1.sequenceIndex, $1.id) }
    }
}
