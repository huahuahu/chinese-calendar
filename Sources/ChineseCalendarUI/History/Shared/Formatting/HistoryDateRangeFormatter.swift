import ChineseCalendarLocalization
import ChineseCalendarPersistence
import Foundation

enum HistoryDateRangeFormatter {
    static func orthodoxPeriodRange(
        start: ChineseDateExpression?,
        end: ChineseDateExpression?
    ) -> String {
        range(
            startText: boundaryText(start),
            endText: boundaryText(end)
        )
    }

    static func claimedDynastyRange(
        start: ChineseDateExpression,
        end: ChineseDateExpression
    ) -> String {
        range(
            startText: boundaryText(start),
            endText: boundaryText(end)
        )
    }

    static func usageRange(
        start: ChineseDateExpression,
        exclusiveEnd: ChineseDateExpression
    ) -> String {
        guard
            start.precision == .year,
            exclusiveEnd.precision == .year,
            let startYear = start.index,
            let exclusiveEndYear = exclusiveEnd.index,
            exclusiveEndYear > startYear
        else {
            return range(
                startText: boundaryText(start),
                endText: boundaryText(exclusiveEnd)
            )
        }

        return range(
            startText: yearText(startYear),
            endText: yearText(exclusiveEndYear - 1)
        )
    }

    static func usageDurationYears(
        start: ChineseDateExpression,
        exclusiveEnd: ChineseDateExpression
    ) -> Int? {
        guard
            start.precision == .year,
            exclusiveEnd.precision == .year,
            let startYear = start.index,
            let exclusiveEndYear = exclusiveEnd.index,
            exclusiveEndYear > startYear
        else {
            return nil
        }

        return exclusiveEndYear - startYear
    }

    static func dynastySpanYears(
        start: ChineseDateExpression?,
        end: ChineseDateExpression?
    ) -> Int? {
        guard
            let start,
            let end,
            start.precision == .year,
            end.precision == .year,
            let startYear = start.index,
            let endYear = end.index,
            endYear >= startYear
        else {
            return nil
        }

        return endYear - startYear
    }

    static func boundaryText(_ expression: ChineseDateExpression?) -> String {
        guard let expression else {
            return String(localized: CalendarStringKey.History.Date.unknown)
        }

        if expression.precision == .year, let year = expression.index {
            return yearText(year)
        }

        let sourceText = expression.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        return sourceText.isEmpty ? String(localized: CalendarStringKey.History.Date.unknown) : sourceText
    }

    static func exclusiveEndBoundaryText(_ expression: ChineseDateExpression) -> String {
        guard expression.precision == .year, let year = expression.index else {
            return boundaryText(expression)
        }

        return yearText(year - 1)
    }

    static func precisionText(_ expression: ChineseDateExpression) -> String {
        String(localized: CalendarDatePrecisionPresentation.title(for: expression.precision))
    }

    static func yearText(_ astronomicalYear: Int) -> String {
        astronomicalYear > 0 ? "\(astronomicalYear)" :
            String(localized: CalendarStringKey.History.Date.beforeCommonEra(year: 1 - astronomicalYear))
    }

    private static func range(startText: String, endText: String) -> String {
        startText == endText ? startText : String(localized: CalendarStringKey.History.Date.range(
            start: startText,
            end: endText
        ))
    }
}
