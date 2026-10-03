import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Test func previewSampleDataProvidesConnectedContentAndEmptyState() throws {
    do {
        let context = try PreviewSampleData.makeContext(includesSampleData: true)
        let modelContext = context.modelContainer.mainContext
        let dynastyID = HistoryPreviewData.dynastyID
        let orthodoxPeriodID = HistoryPreviewData.orthodoxPeriodID
        let emperorID = HistoryPreviewData.emperorID
        let reignEraID = HistoryPreviewData.reignEraID
        let selectedDayIndex = PreviewSampleData.selectedDayIndex

        let dynasties = try modelContext.fetch(
            FetchDescriptor<Dynasty>(predicate: #Predicate { $0.id == dynastyID })
        )
        let periods = try modelContext.fetch(
            FetchDescriptor<OrthodoxPeriod>(predicate: #Predicate { $0.id == orthodoxPeriodID })
        )
        let emperors = try modelContext.fetch(
            FetchDescriptor<Emperor>(predicate: #Predicate { $0.id == emperorID })
        )
        let reignEras = try modelContext.fetch(
            FetchDescriptor<ReignEra>(predicate: #Predicate { $0.id == reignEraID })
        )
        let days = try modelContext.fetch(
            FetchDescriptor<ChineseLunarDay>(
                predicate: #Predicate { $0.dayIndex == selectedDayIndex }
            )
        )

        #expect(dynasties.count == 1)
        #expect(periods.count == 1)
        #expect(emperors.count == 1)
        #expect(reignEras.count == 1)
        #expect(periods.first?.dynasty?.id == dynastyID)
        #expect(reignEras.first?.emperor.id == emperorID)
        #expect(context.selectedDayIndex == selectedDayIndex)
        #expect(days.first?.chineseLunarMonth?.chineseLunarYear?.lunarYearNumber == 2026)
    }

    do {
        let context = try PreviewSampleData.makeContext(includesSampleData: false)
        let years = try context.modelContainer.mainContext.fetch(
            FetchDescriptor<ChineseLunarYear>()
        )
        let periods = try context.modelContainer.mainContext.fetch(
            FetchDescriptor<OrthodoxPeriod>()
        )

        #expect(context.selectedDayIndex == nil)
        #expect(years.isEmpty)
        #expect(periods.isEmpty)
    }
}
