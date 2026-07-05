import ChineseCalendarPersistence
import SwiftUI

struct CalendarPresentationNodeView: View {
    @Bindable var node: CalendarPresentationNode
    let years: [ChineseLunarYear]
    let months: [ChineseLunarMonth]
    let dismiss: () -> Void

    var body: some View {
        NavigationStack(path: $node.path) {
            CalendarRouteDestinationView(
                route: node.route,
                year: year(for: node.route),
                months: months,
                selectedMonthIndex: $node.selectedMonthIndex,
                canSelectPreviousYear: false,
                canSelectNextYear: false,
                selectPreviousYear: {},
                selectNextYear: {},
                selectMonth: selectMonth,
                emptyStateDescription: "请选择一个农历年。"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", action: dismiss)
                }
            }
            .navigationDestination(for: CalendarRoute.self) { route in
                CalendarRouteDestinationView(
                    route: route,
                    year: year(for: route),
                    months: months,
                    selectedMonthIndex: $node.selectedMonthIndex,
                    canSelectPreviousYear: false,
                    canSelectNextYear: false,
                    selectPreviousYear: {},
                    selectNextYear: {},
                    selectMonth: selectMonth,
                    emptyStateDescription: "请选择一个农历年。"
                )
            }
        }
        .sheet(item: $node.sheet) { child in
            CalendarPresentationNodeView(node: child, years: years, months: months) {
                node.dismissSheet()
            }
        }
        .calendarFullScreenCover(item: $node.fullScreen) { child in
            CalendarPresentationNodeView(node: child, years: years, months: months) {
                node.dismissFullScreen()
            }
        }
    }

    private func year(for route: CalendarRoute?) -> ChineseLunarYear? {
        guard let yearNumber = route?.lunarYearNumber else {
            return nil
        }

        return years.first { $0.lunarYearNumber == yearNumber }
    }

    private func selectMonth(_ month: ChineseLunarMonth) {
        node.selectedMonthIndex = month.lunarMonthIndex

        guard node.route.lunarYearNumber != month.lunarYearNumber else {
            return
        }

        node.path = [.lunarYear(month.lunarYearNumber)]
    }
}
