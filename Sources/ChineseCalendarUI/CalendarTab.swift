import Foundation
import SFSafeSymbols

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

    var systemSymbol: SFSymbol {
        switch self {
        case .years:
            .calendar
        case .history:
            .timelineSelection
        }
    }
}
