import Foundation
import NavigationCore

enum CalendarDestination: Codable, NavigationDestination, Identifiable {
    case root
    case calendarHome
    case historyHome
    case settings
    case lunarYear(Int, monthIndex: Int? = nil, dayIndex: Int? = nil)
    case dynasty(orthodoxPeriodID: String)
    case emperorList(dynastyID: String)
    case reignEraList(dynastyID: String)
    case dynastySpan(orthodoxPeriodID: String)
    case reignEra(reignEraID: String)
    case emperor(String)
    case yearPicker(sessionID: UUID)
    case downloadDetails
    #if DEBUG
        case debugNavigation(id: UUID)
        case debugSplit(layout: CalendarDebugSplitLayout)
        case debugSplitDetail(item: CalendarDebugSplitItem, level: Int)
        case debugNavigationTabs(id: UUID)
        case downloadPreview(sessionID: UUID)
        case downloadPreviewScenarios(sessionID: UUID)
        case downloadPreviewSwitch
        case downloadPreviewDetails(sessionID: UUID)
    #endif

    var id: String {
        switch self {
        case .root: "root"
        case .calendarHome: "calendar-home"
        case .historyHome: "history-home"
        case .settings: "settings"
        case let .lunarYear(yearNumber, monthIndex, dayIndex):
            "lunar-year-\(yearNumber)-\(monthIndex.map(String.init) ?? "none")-\(dayIndex.map(String.init) ?? "none")"
        case let .dynasty(orthodoxPeriodID):
            "dynasty-\(orthodoxPeriodID)"
        case let .emperorList(dynastyID):
            "emperor-list-\(dynastyID)"
        case let .reignEraList(dynastyID):
            "reign-era-list-\(dynastyID)"
        case let .dynastySpan(orthodoxPeriodID):
            "dynasty-span-\(orthodoxPeriodID)"
        case let .reignEra(reignEraID):
            "reign-era-\(reignEraID)"
        case let .emperor(emperorID):
            "emperor-\(emperorID)"
        case let .yearPicker(sessionID):
            "year-picker-\(sessionID)"
        case .downloadDetails:
            "download-details"
        #if DEBUG
            case let .debugNavigation(id):
                "debug-navigation-\(id)"
            case let .debugSplit(layout):
                "debug-split-\(layout.rawValue)"
            case let .debugSplitDetail(item, level):
                "debug-split-detail-\(item.rawValue)-\(level)"
            case let .debugNavigationTabs(id):
                "debug-navigation-tabs-\(id)"
            case let .downloadPreview(sessionID):
                "download-preview-\(sessionID)"
            case let .downloadPreviewScenarios(sessionID):
                "download-preview-scenarios-\(sessionID)"
            case .downloadPreviewSwitch:
                "download-preview-switch"
            case let .downloadPreviewDetails(sessionID):
                "download-preview-details-\(sessionID)"
        #endif
        }
    }

    var lunarYearNumber: Int? {
        switch self {
        case let .lunarYear(yearNumber, _, _):
            yearNumber
        default:
            nil
        }
    }

    var providesNavigationContainer: Bool {
        if case .root = self { return true }
        #if DEBUG
            if case .downloadPreview = self { return true }
            if case .debugSplit = self { return true }
            if case .debugNavigationTabs = self { return true }
        #endif
        return false
    }

    var allowedNavigationEntries: Set<NavigationDestinationEntry> {
        switch self {
        case .root: [.root]
        case .calendarHome, .historyHome, .settings: [.stackRoot]
        #if DEBUG
            case .downloadPreview, .debugSplit, .debugNavigationTabs: [.presentation]
            case .debugSplitDetail: [.push]
            case .downloadPreviewScenarios, .downloadPreviewSwitch: [.stackRoot]
        #endif
        default: [.stackRoot, .presentation, .push]
        }
    }

    /// 临时会话依赖当前进程中的回调或下载状态，不能仅凭 ID 跨启动重建。
    var supportsStateRestoration: Bool {
        switch self {
        case .yearPicker, .downloadDetails:
            false
        #if DEBUG
            case .debugNavigation, .debugSplit, .debugSplitDetail, .debugNavigationTabs,
                 .downloadPreview, .downloadPreviewScenarios, .downloadPreviewSwitch,
                 .downloadPreviewDetails:
                false
        #endif
        default:
            true
        }
    }

    var isDownloadDetail: Bool {
        if case .downloadDetails = self { return true }
        #if DEBUG
            if case .downloadPreviewDetails = self { return true }
        #endif
        return false
    }
}
