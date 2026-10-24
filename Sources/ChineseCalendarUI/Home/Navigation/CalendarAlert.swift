import Foundation
import NavigationCore

/// 业务提示的路由值；错误提示只携带恢复建议需要的类别和参数。
nonisolated enum CalendarAlert: NavigationAlertRoute {
    case clearDownloadedData
    case clearDataSucceeded
    case clearDataFailed(failure: CalendarStoreFailure)
    case downloadFailed(failure: CalendarStoreFailure)
    #if DEBUG
        case debugNotice(Int)
        case debugNavigationChoice
    #endif
}
