#if DEBUG
    import ChineseCalendarLocalization
    import SwiftUI

    /// 显示绑定给 SplitView 的 columnVisibility 和 preferredCompactColumn 当前值，
    /// 用于观察系统返回及宽窄切换后，这两个布局状态是否被系统写回更新。
    struct CalendarDebugSplitLayoutStatus: View {
        let state: CalendarDebugSplitState

        var body: some View {
            Section(CalendarStringKey.Debug.Split.layout) {
                LabeledContent {
                    Text(compactColumnTitle)
                } label: {
                    Text(CalendarStringKey.Debug.Split.compactColumn)
                }
                LabeledContent {
                    Text(visibilityTitle)
                } label: {
                    Text(CalendarStringKey.Debug.Split.visibility)
                }
            }
        }

        private var compactColumnTitle: LocalizedStringResource {
            switch state.preferredCompactColumn {
            case .sidebar: CalendarStringKey.Debug.Split.sidebar
            case .content: CalendarStringKey.Debug.Split.content
            default: CalendarStringKey.Debug.Split.detail
            }
        }

        private var visibilityTitle: LocalizedStringResource {
            switch state.columnVisibility {
            case .all: CalendarStringKey.Debug.Split.allColumns
            case .doubleColumn: CalendarStringKey.Debug.Split.doubleColumn
            case .detailOnly: CalendarStringKey.Debug.Split.detailOnly
            default: CalendarStringKey.Debug.Split.automatic
            }
        }
    }
#endif
