import SwiftUI

enum LunarDayGridCellState: CaseIterable {
    case normal
    case selected
    case today
    case todaySelected

    init(isToday: Bool, isSelected: Bool) {
        switch (isToday, isSelected) {
        case (false, false):
            self = .normal
        case (false, true):
            self = .selected
        case (true, false):
            self = .today
        case (true, true):
            self = .todaySelected
        }
    }

    var titleForegroundColor: Color {
        switch self {
        case .normal:
            .primary
        case .selected:
            .calendarSystemBackground
        case .today:
            .accentColor
        case .todaySelected:
            .white
        }
    }

    var titleBackgroundColor: Color {
        switch self {
        case .normal, .today:
            .clear
        case .selected:
            .primary
        case .todaySelected:
            .accentColor
        }
    }
}
