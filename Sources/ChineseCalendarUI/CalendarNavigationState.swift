import Observation
import SwiftUI

@MainActor
@Observable
public final class CalendarNavigationState {
    public enum Route: Hashable, Sendable {
        case lunarYear(Int)
        case dynasty(String)
    }

    public var columnVisibility: NavigationSplitViewVisibility
    public var route: Route?

    public init(
        route: Route? = nil,
        columnVisibility: NavigationSplitViewVisibility = .automatic
    ) {
        self.route = route
        self.columnVisibility = columnVisibility
    }
}
