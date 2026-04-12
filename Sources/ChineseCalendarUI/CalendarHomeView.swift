import ChineseCalendarCore
import ChineseCalendarData
import SwiftUI

public struct CalendarHomeView: View {
    private let selectedDate: ChineseCalendarDate?

    public init(selectedDate: ChineseCalendarDate? = nil) {
        self.selectedDate = selectedDate
    }

    public var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Chinese Calendar", systemImage: "calendar")
            } description: {
                Text(descriptionText)
            }
            .navigationTitle("Calendar")
            .padding()
        }
    }

    private var descriptionText: String {
        guard let selectedDate else {
            return "Calendar browsing UI will appear here once the imported data pipeline is connected."
        }

        let leapPrefix = selectedDate.lunarMonth.isLeapMonth ? "Leap " : ""
        return "Lunar date: \(selectedDate.lunarYear)-\(leapPrefix)\(selectedDate.lunarMonthNumber)-"
            + "\(selectedDate.lunarDayNumber)"
    }
}

#Preview {
    CalendarHomeView()
}
