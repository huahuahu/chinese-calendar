import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 使用正统时期的稳定身份选择朝代，保留同一朝代在不同正统区间中的上下文。
struct CalendarHistorySidebarView: View {
    let periods: [OrthodoxPeriod]
    @Binding var selection: String?

    var body: some View {
        Group {
            if periods.isEmpty {
                ContentUnavailableView {
                    Label(CalendarStringKey.History.Timeline.Empty.title, systemSymbol: .timelineSelection)
                } description: {
                    Text(CalendarStringKey.History.Timeline.Empty.message)
                }
            } else {
                List(selection: $selection) {
                    Section {
                        ForEach(periods, id: \.id) { period in
                            DynastyCard(model: DynastyCardModel(period: period), showsDisclosureIndicator: false)
                                .tag(period.id)
                                .selectionDisabled(period.dynasty == nil)
                                .listRowSeparator(.hidden)
                                .calendarPresentationMenu(destination: .dynasty(orthodoxPeriodID: period.id))
                        }
                    } header: {
                        Text(CalendarStringKey.History.Timeline.subtitle)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle(CalendarStringKey.History.Timeline.title)
    }
}
