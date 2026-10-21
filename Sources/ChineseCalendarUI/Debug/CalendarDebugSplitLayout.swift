#if DEBUG
    import ChineseCalendarLocalization
    import Foundation

    /// 选择 App 演示使用两栏还是三栏；NavigationCore 只管理详情栈，不读取这个布局选项。
    enum CalendarDebugSplitLayout: String, CaseIterable, Identifiable {
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
