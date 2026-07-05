import Foundation
import SFSafeSymbols

enum CalendarTab: Hashable, CaseIterable, Identifiable {
    case years
    case history
    case settings

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .years:
            "日历"
        case .history:
            "历史"
        case .settings:
            "设置"
        }
    }

    var systemSymbol: SFSymbol {
        switch self {
        case .years:
            .calendar
        case .history:
            .timelineSelection
        case .settings:
            .gearshape
        }
    }
}
