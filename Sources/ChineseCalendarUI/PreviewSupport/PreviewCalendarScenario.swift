/// 只决定 Preview 的初始选中日；切换日期仍使用页面自身的数据流。
enum PreviewCalendarScenario {
    case modern
    case beforeCommonEra
    case commonEra
    case civilEraBoundary
    case postNinthMonth

    var selectedDayIndex: Int {
        switch self {
        case .modern:
            PreviewSampleData.selectedDayIndex
        case .beforeCommonEra:
            // 天文年份编号 0（公元前 1 年）对应农历年的十二月最后一天。
            -271
        case .commonEra:
            // 天文年份编号 1（公元 1 年）对应农历年的正月初一。
            -199
        case .civilEraBoundary:
            // 公历纪元边界落在天文年份编号 0 对应农历年的十一月，而非农历年界。
            -399
        case .postNinthMonth:
            -10199
        }
    }
}
