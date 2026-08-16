import SwiftUI

extension View {
    func calendarDestinations(emptyStateDescription: String) -> some View {
        navigationDestination(for: CalendarDestination.self) { destination in
            CalendarDestinationView(
                destination: destination,
                emptyStateDescription: emptyStateDescription
            )
        }
    }
}
