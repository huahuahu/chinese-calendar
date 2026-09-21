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
            return "时间待考"
        }

        if expression.precision == .year, let year = expression.index {
            return yearText(year)
        }

        let sourceText = expression.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        return sourceText.isEmpty ? "时间待考" : sourceText
    }

    static func exclusiveEndBoundaryText(_ expression: ChineseDateExpression) -> String {
        guard expression.precision == .year, let year = expression.index else {
            return boundaryText(expression)
        }

        return yearText(year - 1)
    }

    static func precisionText(_ expression: ChineseDateExpression) -> String {
        switch expression.precision {
        case .year:
            "年精度"
        case .month:
            "月精度"
        case .day:
            "日精度"
        case .range:
            "范围精度"
        case .unknown:
            "精度未知"
        }
    }

    static func yearText(_ astronomicalYear: Int) -> String {
        astronomicalYear > 0 ? "\(astronomicalYear)" : "前\(1 - astronomicalYear)"
    }

    private static func range(startText: String, endText: String) -> String {
        startText == endText ? startText : "\(startText)—\(endText)"
    }
}
