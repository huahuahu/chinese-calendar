import SwiftUI

extension View {
    func calendarDestinations() -> some View {
        navigationDestination(for: CalendarDestination.self) { destination in
            CalendarDestinationView(destination: destination)
        }
    }
}
