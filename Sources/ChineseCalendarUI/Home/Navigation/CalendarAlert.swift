import Foundation
import NavigationCore

/// 业务提示的路由数据，与页面 destination 分开；临时错误文案通过消息 ID 关联。
nonisolated enum CalendarAlert: NavigationAlertRoute {
    case clearDownloadedData
    case clearDataSucceeded
    case clearDataFailed(messageID: CalendarAlertMessageID)
    case downloadFailed(messageID: CalendarAlertMessageID)
    #if DEBUG
        case debugNotice(Int)
        case debugNavigationChoice
    #endif

    enum Action: Hashable {
        case acknowledge, cancel, clearDownloadedData
        #if DEBUG
            case openHistory
        #endif
    }

    var messageID: CalendarAlertMessageID? {
        switch self {
        case let .clearDataFailed(id), let .downloadFailed(id): id
        default: nil
        }
    }
}
