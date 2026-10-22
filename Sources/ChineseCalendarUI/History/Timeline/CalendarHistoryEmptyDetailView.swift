import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

struct CalendarHistoryEmptyDetailView: View {
    var body: some View {
        ContentUnavailableView {
            Label(CalendarStringKey.History.Split.chooseContentTitle, systemSymbol: .listBullet)
        } description: {
            Text(CalendarStringKey.History.Split.chooseContentMessage)
        }
        .navigationTitle(CalendarTab.history.title)
    }
}
