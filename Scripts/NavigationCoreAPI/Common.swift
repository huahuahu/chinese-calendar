import NavigationCore
import SwiftUI

nonisolated enum APIScope: NavigationScope { case home }
nonisolated enum APIDestination: NavigationDestination {
    case home, detail
}

nonisolated enum APIAlert: NavigationAlertRoute { case notice }
typealias APIRouter = NavigationRouter<APIScope, APIDestination, APIAlert>

@MainActor
struct APIConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = APIScope
    typealias Destination = APIDestination
    typealias AlertRoute = APIAlert

    func destination(for destination: APIDestination) -> some View {
        Text(String(describing: destination))
    }
}
