import Observation
import SwiftUI

/// 前两栏的业务选择投影详情根，只有栏布局由此状态单独保存。
@MainActor
@Observable
final class CalendarHistoryState {
    private let navigation: CalendarNavigationContext
    var columnVisibility: NavigationSplitViewVisibility = .all
    var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var orthodoxPeriodID: String? {
        get {
            switch navigation.rootDestination {
            case let .historyDetail(orthodoxPeriodID, _), let .historyEmperor(orthodoxPeriodID, _):
                orthodoxPeriodID
            default:
                nil
            }
        }
        set { selectOrthodoxPeriod(newValue) }
    }

    var section: CalendarHistorySection? {
        get {
            switch navigation.rootDestination {
            case let .historyDetail(_, section): section
            case .historyEmperor: .emperors
            default: nil
            }
        }
        set { selectSection(newValue) }
    }

    init(navigation: CalendarNavigationContext) {
        self.navigation = navigation
        preferredCompactColumn = Self.compactColumn(for: navigation.rootDestination) ?? .sidebar
    }

    @discardableResult
    func selectOrthodoxPeriod(_ orthodoxPeriodID: String?) -> Bool {
        let root = orthodoxPeriodID.map {
            CalendarDestination.historyDetail(orthodoxPeriodID: $0, section: nil)
        } ?? .historyEmpty
        let accepted = self.orthodoxPeriodID != orthodoxPeriodID || orthodoxPeriodID == nil
            ? navigation.setRootDestination(root)
            : navigation.setPath(navigation.path)
        guard accepted.isApplied else { return false }
        preferredCompactColumn = orthodoxPeriodID == nil ? .sidebar : .content
        return true
    }

    @discardableResult
    func selectSection(_ section: CalendarHistorySection?) -> Bool {
        guard let orthodoxPeriodID else { return false }
        let root = CalendarDestination.historyDetail(orthodoxPeriodID: orthodoxPeriodID, section: section)
        let accepted = navigation.rootDestination != root || section == nil
            ? navigation.setRootDestination(root)
            : navigation.setPath(navigation.path)
        guard accepted.isApplied else { return false }
        preferredCompactColumn = section == nil ? .content : .detail
        return true
    }

    /// 外部请求实际应用后才根据新根移动紧凑栏；确认和关闭事务期间保持原布局。
    @discardableResult
    func synchronizeRoot() -> Bool {
        guard let column = Self.compactColumn(for: navigation.rootDestination) else { return false }
        guard navigation.setPath(navigation.path).isApplied else { return false }
        preferredCompactColumn = column
        return true
    }

    private static func compactColumn(for destination: CalendarDestination?) -> NavigationSplitViewColumn? {
        switch destination {
        case .historyEmpty: .sidebar
        case let .historyDetail(_, section): section == nil ? .content : .detail
        case .emperor, .historyEmperor: .detail
        default: nil
        }
    }

    /// 页面查询到皇帝所属正统时期后补齐父级；已被新请求替换的根不会接收旧查询结果。
    @discardableResult
    func resolveEmperorRoot(emperorID: String, orthodoxPeriodID: String) -> Bool {
        guard navigation.rootDestination == .emperor(emperorID) else { return false }
        // 皇帝本身保留为详情根，避免折叠栏切换期间先换列表再补 push。
        guard navigation.setRootDestination(.historyEmperor(orthodoxPeriodID: orthodoxPeriodID, emperorID: emperorID))
            .isApplied
        else { return false }
        preferredCompactColumn = .detail
        return true
    }
}
