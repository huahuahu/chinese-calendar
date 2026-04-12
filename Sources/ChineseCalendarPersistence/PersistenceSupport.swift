import Foundation
import SwiftData

public enum CivilCalendarStyle: String, Codable, CaseIterable, Sendable {
    case julian
    case gregorian
}

public struct StemBranch: Codable, Hashable, Sendable {
    public let stem: String
    public let branch: String

    public var displayName: String {
        stem + branch
    }

    public init(stem: String, branch: String) {
        self.stem = stem
        self.branch = branch
    }
}

public enum ChineseCalendarModelSchema {
    public static let version = Schema.Version(1, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        ChineseCalendarDay.self,
        CivilDateRecord.self,
        ChineseLunarYearInstance.self,
        ChineseLunarMonthInstance.self,
        Dynasty.self,
        Emperor.self,
        ReignEra.self,
        ReignEraAssignment.self
    ]
}
