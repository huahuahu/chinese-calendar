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

    /// 返回进入目标年份时应展示的边界月份。
    func destinationMonthIndex(in chronologicalMonthIndices: [Int]) -> Int? {
        switch self {
        case .earlier:
            chronologicalMonthIndices.last
        case .later:
            chronologicalMonthIndices.first
        }
    }
}
