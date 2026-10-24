import NavigationCore
import Observation
import SwiftUI

/// 负责应用级事件；页面流程由发起页面的 feature 自己持有。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter
    let downloadDetails = CalendarDownloadDetailsFeature()

    init(router: CalendarRouter = CalendarRouter()) {
        self.router = router
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        _ = router.openDeepLink(deepLink, confirmIfPresented: true)
    }
}
