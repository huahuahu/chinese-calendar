import ChineseCalendarLocalization
import ChineseCalendarPersistence
import Foundation

/// 将模型中的年、月、日等日期精度，转换为界面可显示的本地化名称。
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
