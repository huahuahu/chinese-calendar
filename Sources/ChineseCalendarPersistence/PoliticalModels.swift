import Foundation
import SwiftData

@Model
public final class Dynasty {
    #Unique<Dynasty>([\.id])

    public var id: String
    public var name: String
    public var startCalendarDayIndex: Int?
    public var endCalendarDayIndex: Int?
    public var sortName: String
    public var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \Emperor.dynasty)
    public var emperors: [Emperor]

    public init(
        id: String,
        name: String,
        startCalendarDayIndex: Int? = nil,
        endCalendarDayIndex: Int? = nil,
        sortName: String? = nil,
        notes: String? = nil,
        emperors: [Emperor] = []
    ) {
        self.id = id
        self.name = name
        self.startCalendarDayIndex = startCalendarDayIndex
        self.endCalendarDayIndex = endCalendarDayIndex
        self.sortName = sortName ?? name
        self.notes = notes
        self.emperors = emperors
    }
}

@Model
public final class Emperor {
    #Unique<Emperor>([\.id])

    public var id: String
    public var dynastyID: String
    public var name: String
    public var templeName: String?
    public var posthumousTitle: String?
    public var personalName: String?

    public var dynasty: Dynasty?

    @Relationship(deleteRule: .cascade, inverse: \ReignEra.emperor)
    public var reignEras: [ReignEra]

    public init(
        id: String,
        dynastyID: String,
        name: String,
        templeName: String? = nil,
        posthumousTitle: String? = nil,
        personalName: String? = nil,
        dynasty: Dynasty? = nil,
        reignEras: [ReignEra] = []
    ) {
        self.id = id
        self.dynastyID = dynastyID
        self.name = name
        self.templeName = templeName
        self.posthumousTitle = posthumousTitle
        self.personalName = personalName
        self.dynasty = dynasty
        self.reignEras = reignEras
    }
}

@Model
public final class ReignEra {
    #Unique<ReignEra>([\.id])

    public var id: String
    public var emperorID: String
    public var name: String
    public var startCalendarDayIndex: Int?
    public var endCalendarDayIndex: Int?
    public var eraSequence: Int?

    public var emperor: Emperor?

    @Relationship(deleteRule: .cascade, inverse: \ReignEraAssignment.reignEra)
    public var assignments: [ReignEraAssignment]

    public init(
        id: String,
        emperorID: String,
        name: String,
        startCalendarDayIndex: Int? = nil,
        endCalendarDayIndex: Int? = nil,
        eraSequence: Int? = nil,
        emperor: Emperor? = nil,
        assignments: [ReignEraAssignment] = []
    ) {
        self.id = id
        self.emperorID = emperorID
        self.name = name
        self.startCalendarDayIndex = startCalendarDayIndex
        self.endCalendarDayIndex = endCalendarDayIndex
        self.eraSequence = eraSequence
        self.emperor = emperor
        self.assignments = assignments
    }
}

@Model
public final class ReignEraAssignment {
    #Unique<ReignEraAssignment>([\.dayIndex, \.reignEraID])

    public var dayIndex: Int
    public var reignEraID: String
    public var regnalYearNumber: Int
    public var displayOrder: Int
    public var isPrimary: Bool
    public var sourceNote: String?

    public var chineseCalendarDay: ChineseCalendarDay?
    public var reignEra: ReignEra?

    public init(
        dayIndex: Int,
        reignEraID: String,
        regnalYearNumber: Int,
        displayOrder: Int,
        isPrimary: Bool,
        sourceNote: String? = nil,
        chineseCalendarDay: ChineseCalendarDay? = nil,
        reignEra: ReignEra? = nil
    ) {
        self.dayIndex = dayIndex
        self.reignEraID = reignEraID
        self.regnalYearNumber = regnalYearNumber
        self.displayOrder = displayOrder
        self.isPrimary = isPrimary
        self.sourceNote = sourceNote
        self.chineseCalendarDay = chineseCalendarDay
        self.reignEra = reignEra
    }
}
