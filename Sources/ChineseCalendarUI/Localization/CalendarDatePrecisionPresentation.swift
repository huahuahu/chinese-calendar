import ChineseCalendarLocalization
import ChineseCalendarPersistence
import Foundation

/// 在界面边界将数据模型的日期精度映射为基础文案资源。
enum CalendarDatePrecisionPresentation {
    static func title(for precision: ChineseDatePrecision) -> LocalizedStringResource {
        switch precision {
        case .year: CalendarStringKey.Common.DatePrecision.year
        case .month: CalendarStringKey.Common.DatePrecision.month
        case .day: CalendarStringKey.Common.DatePrecision.day
        case .range: CalendarStringKey.Common.DatePrecision.range
        case .unknown: CalendarStringKey.Common.DatePrecision.unknown
        }
    }
}
