/// 从导航地址传入、只应用一次的日历初始落点。
struct LunarCalendarLanding: Equatable {
    let yearNumber: Int
    let monthIndex: Int?
    let dayIndex: Int?
}
