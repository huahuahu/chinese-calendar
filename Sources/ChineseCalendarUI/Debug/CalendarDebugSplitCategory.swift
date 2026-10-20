#if DEBUG
    import ChineseCalendarLocalization
    import Foundation

    enum CalendarDebugSplitCategory: String, CaseIterable, Identifiable {
        case first
        case second

        var id: Self {
            self
        }

        var title: LocalizedStringResource {
            switch self {
            case .first: CalendarStringKey.Debug.Split.firstCategory
            case .second: CalendarStringKey.Debug.Split.secondCategory
            }
        }

        var items: [CalendarDebugSplitItem] {
            switch self {
            case .first: [.first, .second]
            case .second: [.third, .fourth]
            }
        }
    }
#endif
