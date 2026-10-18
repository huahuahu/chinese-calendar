#if DEBUG
    import ChineseCalendarLocalization
    import SwiftUI

    /// 与业务页面一样只接收路由数据，导航容器和模态宿主均由 NavigationCore 提供。
    struct CalendarDebugNavigationView: View {
        let id: UUID
        // 宿主注入当前栈的上下文；作为模态展示时，这里对应模态自己的栈，与底层 Tab 的 path 独立。
        // 普通业务页按需使用局部导航能力，无需像本调试页一样读取栈身份和 path 深度。
        @Environment(CalendarNavigationContext.self) private var navigation
        @Environment(CalendarPresentationContext.self) private var presentation

        var body: some View {
            Form {
                Section {
                    LabeledContent {
                        Text(scopeTitle)
                    } label: {
                        Text(CalendarStringKey.Debug.Navigation.scope)
                    }
                    LabeledContent {
                        Text(navigation.path.count, format: .number)
                    } label: {
                        Text(CalendarStringKey.Debug.Navigation.pathDepth)
                    }
                    LabeledContent {
                        Text(id.uuidString)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    } label: {
                        Text(CalendarStringKey.Debug.Navigation.pageIdentity)
                    }
                } footer: {
                    Text(CalendarStringKey.Debug.Navigation.message)
                }

                CalendarDebugNavigationActions()
            }
            .navigationTitle(CalendarStringKey.Debug.Navigation.title)
            .navigationBarTitleDisplayMode(.inline)
        }

        private var scopeTitle: LocalizedStringResource {
            if presentation.isPresented { return CalendarStringKey.Debug.Navigation.modalScope }
            switch navigation.id {
            case .primary: return CalendarStringKey.Debug.Navigation.rootScope
            case let .scope(tab): return tab.title
            }
        }
    }
#endif
