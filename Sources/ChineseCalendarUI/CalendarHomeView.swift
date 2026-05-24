import ChineseCalendarCore
import ChineseCalendarData
import ChineseCalendarLogging
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

public struct CalendarHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calendarDayCount: Int?

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
            .task {
                await loadCalendarDayCount()
            }
        }
    }

    @MainActor
    private func loadCalendarDayCount() async {
        do {
            calendarDayCount = try modelContext.fetchCount(FetchDescriptor<CalendarDay>())
            ChineseCalendarLog.ui.info("Loaded \(calendarDayCount ?? 0) calendar days for home view")
        } catch {
            ChineseCalendarLog.ui.error(
                "Failed to load calendar day count: \(error.localizedDescription, privacy: .private)"
            )
        }
    }

    private var descriptionText: String {
        guard let selectedDate else {
            guard let calendarDayCount else {
                return "Loading calendar data from SwiftData."
            }

            return "Loaded \(calendarDayCount) calendar days from SwiftData."
        }

        let leapPrefix = selectedDate.lunarMonth.isLeapMonth ? "Leap " : ""
        return "Lunar date: \(selectedDate.lunarYear)-\(leapPrefix)\(selectedDate.lunarMonthNumber)-"
            + "\(selectedDate.lunarDayNumber)"
    }
}

#Preview {
    CalendarHomeView()
}
