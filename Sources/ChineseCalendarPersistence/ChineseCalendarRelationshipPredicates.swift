import Foundation
import SwiftData

/// Indexed relationship filters shared by calendar views and navigation.
public enum ChineseCalendarRelationshipPredicates {
    public static func days(inMonth monthIndex: Int) -> Predicate<ChineseLunarDay> {
        #Predicate<ChineseLunarDay> { day in
            // Optional chaining generates a SQL CASE that scans the full day table.
            // The explicit nil guard safely excludes incomplete records before unwrapping.
            // swiftlint:disable:next force_unwrapping
            !(day.chineseLunarMonth == nil) && day.chineseLunarMonth!.lunarMonthIndex == monthIndex
        }
    }

    public static func months(inYear yearNumber: Int) -> Predicate<ChineseLunarMonth> {
        #Predicate<ChineseLunarMonth> { month in
            // Preserve the same guarded, indexable SQL shape as the day filter.
            // swiftlint:disable:next force_unwrapping
            !(month.chineseLunarYear == nil) && month.chineseLunarYear!.lunarYearNumber == yearNumber
        }
    }
}
