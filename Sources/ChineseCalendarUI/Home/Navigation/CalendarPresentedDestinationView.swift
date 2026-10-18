import SwiftData
import SwiftUI

/// 业务 builder 只负责路由映射和数据环境，容器与局部 Router 由 Core 宿主提供。
struct CalendarPresentedDestinationView: View {
    let destination: CalendarDestination
    let storeCoordinator: ChineseCalendarStoreCoordinator?

    var body: some View {
        if let storeCoordinator, case let .ready(container, contentLevel, identityToken) = storeCoordinator.state {
            CalendarDestinationView(destination: destination, storeCoordinator: storeCoordinator)
                .modelContainer(container)
                .environment(\.calendarStoreContentLevel, contentLevel)
                .id(storeCoordinator.storeIdentity(contentLevel: contentLevel, identityToken: identityToken))
        } else {
            CalendarDestinationView(destination: destination, storeCoordinator: storeCoordinator)
        }
    }
}
