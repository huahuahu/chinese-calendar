import Foundation

struct HistoryBoundaryEvent: Identifiable {
    let id: String
    let orthodoxPeriodID: String
    let dateExpressionID: String
    let timeText: String
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let sequenceIndex: Int
}
