import Foundation

#if canImport(OSLog)
    import OSLog
#endif

/// 为 Instruments 提供低开销的日历性能区间与事件。
///
/// Debug 构建默认启用。Release 构建仅在进程环境显式设置
/// `CHINESE_CALENDAR_PERFORMANCE_SIGNPOSTS=1` 时启用；共享 Xcode scheme 会在
/// Profile action 中传入该变量，但 Archive/App Store 运行不会自动启用。
@MainActor
public final class ChineseCalendarPerformanceSignposts {
    public static let shared = ChineseCalendarPerformanceSignposts()
    public static let environmentVariable = "CHINESE_CALENDAR_PERFORMANCE_SIGNPOSTS"

    public var isEnabled: Bool {
        #if DEBUG
            true
        #else
            ProcessInfo.processInfo.environment[Self.environmentVariable] == "1"
        #endif
    }

    #if canImport(OSLog)
        private struct ActiveMonthSwitch {
            let targetMonthIndex: Int
            let id: OSSignpostID
            let state: OSSignpostIntervalState
        }

        private let signposter = OSSignposter(
            subsystem: ChineseCalendarLog.subsystem,
            category: .pointsOfInterest
        )
        private var activeMonthSwitch: ActiveMonthSwitch?
    #endif

    private init() {}

    /// 开始测量从用户选择月份到新月份默认日期完成选择的总耗时。
    public func beginMonthSwitch(from sourceMonthIndex: Int?, to targetMonthIndex: Int, crossesYear: Bool) {
        guard isEnabled else {
            return
        }

        #if canImport(OSLog)
            if let activeMonthSwitch {
                signposter.endInterval(
                    "Month Switch",
                    activeMonthSwitch.state,
                    "targetMonthIndex: \(activeMonthSwitch.targetMonthIndex, privacy: .public), result: superseded"
                )
            }

            let id = signposter.makeSignpostID()
            let sourceMonthIndex = sourceMonthIndex ?? -1
            let state = signposter.beginInterval(
                "Month Switch",
                id: id,
                "sourceMonthIndex: \(sourceMonthIndex, privacy: .public), targetMonthIndex: \(targetMonthIndex, privacy: .public), crossesYear: \(crossesYear, privacy: .public)"
            )
            activeMonthSwitch = ActiveMonthSwitch(
                targetMonthIndex: targetMonthIndex,
                id: id,
                state: state
            )
        #endif
    }

    /// 标记目标月份的 SwiftData 查询结果已经可供月视图使用。
    public func monthDaysAvailable(monthIndex: Int, dayCount: Int) {
        guard isEnabled else {
            return
        }

        #if canImport(OSLog)
            guard let activeMonthSwitch, activeMonthSwitch.targetMonthIndex == monthIndex else {
                return
            }

            signposter.emitEvent(
                "Month Days Available",
                id: activeMonthSwitch.id,
                "monthIndex: \(monthIndex, privacy: .public), dayCount: \(dayCount, privacy: .public)"
            )
        #endif
    }

    /// 在月视图完成默认日期选择后结束本次月份切换区间。
    public func endMonthSwitch(monthIndex: Int, dayCount: Int, selectedDayIndex: Int?) {
        guard isEnabled else {
            return
        }

        #if canImport(OSLog)
            guard let activeMonthSwitch, activeMonthSwitch.targetMonthIndex == monthIndex else {
                return
            }

            let selectedDayIndex = selectedDayIndex ?? -1
            signposter.endInterval(
                "Month Switch",
                activeMonthSwitch.state,
                "monthIndex: \(monthIndex, privacy: .public), dayCount: \(dayCount, privacy: .public), selectedDayIndex: \(selectedDayIndex, privacy: .public), result: ready"
            )
            self.activeMonthSwitch = nil
        #endif
    }
}
