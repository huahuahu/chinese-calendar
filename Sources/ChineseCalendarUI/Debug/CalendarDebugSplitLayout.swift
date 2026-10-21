#if DEBUG
    import ChineseCalendarLocalization
    import Foundation

    /// 只描述 App 演示的布局，不进入 NavigationCore 的容器模型。
    enum CalendarDebugSplitLayout: String, Codable, CaseIterable, Identifiable {
        case twoColumn
        case threeColumn

        var id: Self {
            self
        }

        var title: LocalizedStringResource {
            switch self {
            case .twoColumn: CalendarStringKey.Debug.Split.twoColumn
            case .threeColumn: CalendarStringKey.Debug.Split.threeColumn
            }
        }
    }
#endif
