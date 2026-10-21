#if DEBUG
    import ChineseCalendarLocalization
    import Foundation

    enum CalendarDebugSplitItem: String, CaseIterable, Identifiable {
        case first
        case second
        case third
        case fourth

        var id: Self {
            self
        }

        var title: LocalizedStringResource {
            switch self {
            case .first: CalendarStringKey.Debug.Split.firstItem
            case .second: CalendarStringKey.Debug.Split.secondItem
            case .third: CalendarStringKey.Debug.Split.thirdItem
            case .fourth: CalendarStringKey.Debug.Split.fourthItem
            }
        }

        var category: CalendarDebugSplitCategory {
            switch self {
            case .first, .second: .first
            case .third, .fourth: .second
            }
        }

        var next: Self {
            switch self {
            case .first: .second
            case .second: .third
            case .third: .fourth
            case .fourth: .first
            }
        }
    }
#endif
