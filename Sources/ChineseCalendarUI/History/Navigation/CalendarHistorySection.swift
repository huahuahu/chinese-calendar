/// 朝代资料入口；具体资料身份由历史详情根中的正统时期确定。
enum CalendarHistorySection: String, CaseIterable, Hashable, Identifiable {
    case emperors
    case reignEras
    case orthodoxSpan

    var id: Self {
        self
    }
}
