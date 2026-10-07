import ChineseCalendarLocalization
import Foundation
import SFSafeSymbols

enum CalendarTab: Hashable, CaseIterable, Identifiable {
    case years
    case history
    case settings

    var id: Self {
        self
    }

    var title: LocalizedStringResource {
        switch self {
        case .years:
            CalendarStringKey.Calendar.title
        case .history:
            CalendarStringKey.History.Timeline.title
        case .settings:
            CalendarStringKey.Settings.title
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
