import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Test func historyPreviewContainerProvidesConnectedHistoryRecords() throws {
    let context = HistoryPreviewData.container.mainContext
    let dynastyID = HistoryPreviewData.dynastyID
    let orthodoxPeriodID = HistoryPreviewData.orthodoxPeriodID
    let emperorID = HistoryPreviewData.emperorID
    let reignEraID = HistoryPreviewData.reignEraID

    let dynasties = try context.fetch(
        FetchDescriptor<Dynasty>(predicate: #Predicate { $0.id == dynastyID })
    )
    let periods = try context.fetch(
        FetchDescriptor<OrthodoxPeriod>(predicate: #Predicate { $0.id == orthodoxPeriodID })
    )
    let emperors = try context.fetch(
        FetchDescriptor<Emperor>(predicate: #Predicate { $0.id == emperorID })
    )
    let reignEras = try context.fetch(
        FetchDescriptor<ReignEra>(predicate: #Predicate { $0.id == reignEraID })
    )

    #expect(dynasties.count == 1)
    #expect(periods.count == 1)
    #expect(emperors.count == 1)
    #expect(reignEras.count == 1)
    #expect(periods.first?.dynasty?.id == dynastyID)
    #expect(reignEras.first?.emperor.id == emperorID)
}
