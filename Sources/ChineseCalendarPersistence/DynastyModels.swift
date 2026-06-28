import Foundation
import SwiftData

public enum ChineseDatePrecision: String, Codable, CaseIterable, Sendable {
    case year
    case month
    case day
    case range
    case unknown
}

@Model
public final class Dynasty {
    #Unique<Dynasty>([\.id])
    #Index<Dynasty>([\.id], [\.name])

    public var id: String
    public var name: String
    public var shortName: String?

    @Relationship(deleteRule: .cascade)
    public var claimedStartDate: ChineseDateExpression

    @Relationship(deleteRule: .cascade)
    public var claimedEndDate: ChineseDateExpression

    @Relationship(deleteRule: .cascade, inverse: \Emperor.dynasty)
    public var emperors: [Emperor]

    public var note: String?

    public init(
        id: String,
        name: String,
        shortName: String? = nil,
        claimedStartDate: ChineseDateExpression,
        claimedEndDate: ChineseDateExpression,
        emperors: [Emperor] = [],
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.claimedStartDate = claimedStartDate
        self.claimedEndDate = claimedEndDate
        self.emperors = emperors
        self.note = note
    }
}

@Model
public final class ChineseDateExpression {
    #Unique<ChineseDateExpression>([\.id])
    #Index<ChineseDateExpression>([\.id], [\.precisionRawValue, \.index])

    public var id: String
    public var precisionRawValue: String
    public var index: Int?

    @Relationship(deleteRule: .cascade)
    public var uncertainRange: ChineseDateRange?

    public var sourceText: String
    public var note: String?

    public var precision: ChineseDatePrecision {
        get { ChineseDatePrecision(rawValue: precisionRawValue) ?? .unknown }
        set { precisionRawValue = newValue.rawValue }
    }

    public init(
        id: String,
        precision: ChineseDatePrecision,
        index: Int? = nil,
        uncertainRange: ChineseDateRange? = nil,
        sourceText: String,
        note: String? = nil
    ) {
        self.id = id
        precisionRawValue = precision.rawValue
        self.index = index
        self.uncertainRange = uncertainRange
        self.sourceText = sourceText
        self.note = note
    }
}

@Model
public final class ChineseDateRange {
    #Unique<ChineseDateRange>([\.id])

    public var id: String

    @Relationship(deleteRule: .cascade)
    public var lowerBound: ChineseDateBound

    @Relationship(deleteRule: .cascade)
    public var upperBound: ChineseDateBound

    public init(
        id: String,
        lowerBound: ChineseDateBound,
        upperBound: ChineseDateBound
    ) {
        self.id = id
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

@Model
public final class ChineseDateBound {
    #Unique<ChineseDateBound>([\.id])

    public var id: String
    public var precisionRawValue: String
    public var index: Int

    public var precision: ChineseDatePrecision {
        get { ChineseDatePrecision(rawValue: precisionRawValue) ?? .unknown }
        set { precisionRawValue = newValue.rawValue }
    }

    public init(id: String, precision: ChineseDatePrecision, index: Int) {
        self.id = id
        precisionRawValue = precision.rawValue
        self.index = index
    }
}

@Model
public final class OrthodoxTradition {
    #Unique<OrthodoxTradition>([\.id])
    #Index<OrthodoxTradition>([\.id])

    public var id: String
    public var name: String
    public var note: String?

    public init(id: String, name: String, note: String? = nil) {
        self.id = id
        self.name = name
        self.note = note
    }
}

@Model
public final class OrthodoxBoundary {
    #Unique<OrthodoxBoundary>([\.id])
    #Index<OrthodoxBoundary>([\.id], [\.traditionID])

    public var id: String
    public var traditionID: String
    public var dateExpressionID: String
    public var note: String?

    public var tradition: OrthodoxTradition?

    @Relationship(deleteRule: .cascade)
    public var date: ChineseDateExpression

    public init(
        id: String,
        traditionID: String,
        dateExpressionID: String,
        tradition: OrthodoxTradition? = nil,
        date: ChineseDateExpression,
        note: String? = nil
    ) {
        self.id = id
        self.traditionID = traditionID
        self.dateExpressionID = dateExpressionID
        self.tradition = tradition
        self.date = date
        self.note = note
    }
}

@Model
public final class OrthodoxPeriod {
    #Unique<OrthodoxPeriod>([\.id])
    #Index<OrthodoxPeriod>([\.id], [\.traditionID, \.sequenceIndex], [\.segmentIndex])

    public var id: String
    public var traditionID: String
    public var dynastyID: String
    public var startBoundaryID: String
    public var endBoundaryID: String
    public var sequenceIndex: Int
    public var segmentIndex: Int
    public var segmentName: String
    public var note: String?

    public var tradition: OrthodoxTradition?
    public var dynasty: Dynasty?
    public var startBoundary: OrthodoxBoundary?
    public var endBoundary: OrthodoxBoundary?

    public init(
        id: String,
        traditionID: String,
        dynastyID: String,
        startBoundaryID: String,
        endBoundaryID: String,
        sequenceIndex: Int,
        segmentIndex: Int,
        segmentName: String,
        tradition: OrthodoxTradition? = nil,
        dynasty: Dynasty? = nil,
        startBoundary: OrthodoxBoundary? = nil,
        endBoundary: OrthodoxBoundary? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.traditionID = traditionID
        self.dynastyID = dynastyID
        self.startBoundaryID = startBoundaryID
        self.endBoundaryID = endBoundaryID
        self.sequenceIndex = sequenceIndex
        self.segmentIndex = segmentIndex
        self.segmentName = segmentName
        self.tradition = tradition
        self.dynasty = dynasty
        self.startBoundary = startBoundary
        self.endBoundary = endBoundary
        self.note = note
    }
}
