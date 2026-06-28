import Foundation

enum CalendarTab: Hashable, CaseIterable, Identifiable {
    case years
    case history

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .years:
            "年份"
        case .history:
            "历史"
        }
    }

    var systemImage: String {
        switch self {
        case .years:
            "calendar"
        case .history:
            "timeline.selection"
        }
    }
}
