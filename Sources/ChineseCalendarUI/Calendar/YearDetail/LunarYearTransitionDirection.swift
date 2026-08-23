import SwiftUI

/// 描述农历年内容沿时间轴切换的方向。
enum LunarYearTransitionDirection: Equatable {
    case earlier
    case later

    init?(from oldYearNumber: Int, to newYearNumber: Int) {
        guard oldYearNumber != newYearNumber else {
            return nil
        }

        self = newYearNumber > oldYearNumber ? .later : .earlier
    }

    func transition(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }

        return switch self {
        case .earlier:
            .push(from: .leading)
        case .later:
            .push(from: .trailing)
        }
    }
}
