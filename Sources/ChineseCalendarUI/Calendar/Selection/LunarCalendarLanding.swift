/// 日历导航的单次落点，用于首次打开页面或切换到指定年、月、日。
///
/// 年、月、日是互斥的导航意图；解析后保存月或日精度的浏览位置。
enum LunarCalendarLanding: Equatable {
    /// 由月份数据和当前日序定位今天，不预先计算农历年份。
    case today

    /// 定位到某个农历年，由解析器选择该年的默认月份或日期。
    case year(number: Int)

    /// 按内部连续月序定位到某个农历月，index 不是一年中的月号。
    case month(index: Int)

    /// 按内部日序定位到具体农历日，index 不是月内日号或儒略日数。
    case day(index: Int)
}
