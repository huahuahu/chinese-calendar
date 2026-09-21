import SwiftUI

/// 供导航容器使用，将 CalendarDestination 分发到对应页面。
struct CalendarDestinationView: View {
    let destination: CalendarDestination

    var body: some View {
        Group {
            switch destination {
            case let .lunarYear(yearNumber, monthIndex, dayIndex):
                LunarYearDestinationView(
                    yearNumber: yearNumber,
                    monthIndex: monthIndex,
                    dayIndex: dayIndex
                )
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
            case let .yearPicker(yearPicker):
                CalendarYearPickerDestinationView(destination: yearPicker)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
    }
}
