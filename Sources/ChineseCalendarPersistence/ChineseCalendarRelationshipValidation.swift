import Foundation
import SwiftData

/// Reject incomplete static data before publishing or installing a seed store.
/// Optional inverse relationships allow missing data to be diagnosed without force-unwrapping.
public enum ChineseCalendarRelationshipValidation {
    public static func validate(in context: ModelContext) throws {
        try requireComplete(
            context.fetchCount(FetchDescriptor<ChineseLunarDay>(predicate: #Predicate {
                $0.chineseLunarMonth == nil || $0.calendarDay == nil
            })),
            model: "ChineseLunarDay"
        )
        try requireComplete(
            context.fetchCount(FetchDescriptor<ChineseLunarMonth>(predicate: #Predicate {
                $0.chineseLunarYear == nil
            })),
            model: "ChineseLunarMonth"
        )
        try requireComplete(
            context.fetchCount(FetchDescriptor<OrthodoxBoundary>(predicate: #Predicate {
                $0.tradition == nil
            })),
            model: "OrthodoxBoundary"
        )
        let periods = try context.fetch(FetchDescriptor<OrthodoxPeriod>())
        for period in periods {
            guard period.dynasty != nil,
                  let traditionID = period.tradition?.id,
                  period.startBoundary?.tradition?.id == traditionID,
                  period.endBoundary?.tradition?.id == traditionID
            else {
                throw InvalidRelationships(model: "OrthodoxPeriod \(period.id)", count: 1)
            }
        }
    }

    private static func requireComplete(_ count: Int, model: String) throws {
        guard count == 0 else { throw InvalidRelationships(model: model, count: count) }
    }

    public struct InvalidRelationships: LocalizedError {
        public let model: String
        public let count: Int

        public var errorDescription: String? {
            "\(model): \(count) record(s) have missing or inconsistent required relationships."
        }
    }
}
