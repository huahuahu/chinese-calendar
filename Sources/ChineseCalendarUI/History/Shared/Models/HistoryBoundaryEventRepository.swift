import ChineseCalendarLocalization
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
                title: CalendarStringKey.History.Boundary.Event.startTitle(dynasty: dynastyName),
                detail: CalendarStringKey.History.Boundary.Event.startDetail(dynasty: dynastyName),
                sequenceIndex: 0
            ))
        }

        if let endDate = period.endBoundary?.date {
            events.append(HistoryBoundaryEvent(
                id: "\(period.id)-end",
                orthodoxPeriodID: period.id,
                dateExpressionID: endDate.id,
                timeText: HistoryDateRangeFormatter.boundaryText(endDate),
                title: CalendarStringKey.History.Boundary.Event.endTitle(dynasty: dynastyName),
                detail: CalendarStringKey.History.Boundary.Event.endDetail(dynasty: dynastyName),
                sequenceIndex: 1
            ))
        }

        return events.sorted { ($0.sequenceIndex, $0.id) < ($1.sequenceIndex, $1.id) }
    }
}
