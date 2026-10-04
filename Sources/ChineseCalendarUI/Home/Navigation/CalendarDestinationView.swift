import SwiftUI

/// 供导航容器使用，将 CalendarDestination 分发到对应页面。
struct CalendarDestinationView: View {
    let destination: CalendarDestination

    var body: some View {
        Group {
            switch destination {
            case let .lunarYear(yearNumber, monthIndex, dayIndex):
                // 在导航边界选取地址中最具体的定位信息，页面只接收一种落点。
                let landing: LunarCalendarLanding = if let dayIndex {
                    .day(index: dayIndex)
                } else if let monthIndex {
                    .month(index: monthIndex)
                } else {
                    .year(number: yearNumber)
                }

                LunarYearDestinationView(landing: landing)
                    .id(destination)
            case let .dynasty(orthodoxPeriodID):
                DynastyDetailView(orthodoxPeriodID: orthodoxPeriodID)
            case let .emperorList(dynastyID):
                EmperorListView(dynastyID: dynastyID)
            case let .reignEraList(dynastyID):
                ReignEraListView(dynastyID: dynastyID)
            case let .dynastySpan(orthodoxPeriodID):
                DynastySpanDetailView(orthodoxPeriodID: orthodoxPeriodID)
            case let .reignEra(reignEraID):
                ReignEraDetailView(reignEraID: reignEraID)
            case let .emperor(emperorID):
                EmperorDetailView(emperorID: emperorID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
    }
}
