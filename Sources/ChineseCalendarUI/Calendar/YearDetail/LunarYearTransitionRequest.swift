/// 保存一次年份跳转在源年份完成滚动后需要提交的目标状态。
struct LunarYearTransitionRequest: Equatable {
    let sourceYearNumber: Int
    let sourceMonthIndex: Int
    let destinationYearNumber: Int
    let destinationMonthIndex: Int?
}
