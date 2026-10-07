import ChineseCalendarLocalization
import ChineseCalendarPersistence

struct EmperorCardModel: Identifiable {
    let id: String
    let sequenceText: String
    let displayName: String
    let reliableTitle: String?
    let reignRangeText: String
    let durationText: String?
    let reignEraNames: [String]

    init(emperor: Emperor) {
        let segments = emperor.reignSegments.sorted {
            ($0.segmentIndex, $0.sequenceIndex, $0.id) < ($1.segmentIndex, $1.sequenceIndex, $1.id)
        }
        let eras = emperor.reignEras.sorted {
            ($0.sequenceIndex, $0.eraIndexWithinEmperor, $0.id)
                < ($1.sequenceIndex, $1.eraIndexWithinEmperor, $1.id)
        }

        id = emperor.id
        sequenceText = Self.sequenceText(emperor.sequenceIndex + 1)
        displayName = emperor.personalName ?? emperor.displayName
        reliableTitle = emperor.templeName ?? emperor.posthumousName
        reignRangeText = segments.isEmpty
            ? String(localized: CalendarStringKey.History.EmperorCard.unknownReign)
            : CalendarStringKey.Common.List.names(segments.map {
                HistoryDateRangeFormatter.usageRange(
                    start: $0.startDate,
                    exclusiveEnd: $0.endDate
                )
            })
        durationText = Self.durationText(for: segments)
        reignEraNames = eras.map(\.name)
    }

    init(
        id: String,
        sequenceText: String,
        displayName: String,
        reliableTitle: String?,
        reignRangeText: String,
        durationText: String?,
        reignEraNames: [String]
    ) {
        self.id = id
        self.sequenceText = sequenceText
        self.displayName = displayName
        self.reliableTitle = reliableTitle
        self.reignRangeText = reignRangeText
        self.durationText = durationText
        self.reignEraNames = reignEraNames
    }

    var accessibilityLabel: String {
        var parts = [String(localized: CalendarStringKey.History.EmperorCard.accessibilityIntroduction(
            sequence: sequenceText,
            name: displayName
        ))]
        if let reliableTitle {
            parts.append(reliableTitle)
        }
        parts.append(reignRangeText)
        if let durationText {
            parts.append(durationText)
        }
        if !reignEraNames.isEmpty {
            parts
                .append(String(localized: CalendarStringKey.History.EmperorCard
                        .eraNamesAccessibilityLabel(names: CalendarStringKey.Common.List.names(reignEraNames))))
        }
        return CalendarStringKey.Common.List.names(parts)
    }

    private static func durationText(for segments: [EmperorReignSegment]) -> String? {
        let durations = segments.compactMap {
            HistoryDateRangeFormatter.usageDurationYears(
                start: $0.startDate,
                exclusiveEnd: $0.endDate
            )
        }
        guard durations.count == segments.count, !durations.isEmpty else {
            return nil
        }

        let totalYears = durations.reduce(0, +)
        if segments.count == 2 {
            return String(localized: CalendarStringKey.History.EmperorCard.twoReignsDuration(years: totalYears))
        }
        if segments.count > 2 {
            return String(localized: CalendarStringKey.History.EmperorCard.multipleReignsDuration(
                count: segments.count,
                years: totalYears
            ))
        }
        return String(localized: CalendarStringKey.History.Date.duration(years: totalYears))
    }

    private static func sequenceText(_ sequence: Int) -> String {
        sequence < 10 ? "0\(sequence)" : "\(sequence)"
    }
}
