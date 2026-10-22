#if DEBUG
    /// DEBUG 导航提示的选项与普通通知、清理数据动作独立。
    nonisolated enum CalendarDebugNavigationAction: Hashable {
        case openHistory, cancel
    }
#endif
