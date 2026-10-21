#if DEBUG
    import ChineseCalendarLocalization
    import NavigationCore
    import SFSafeSymbols
    import SwiftUI

    /// SplitView 由 App 组合；仅 detail 使用 SDK 的单栈与当前层的呈现宿主。
    struct CalendarDebugSplitView: View {
        let layout: CalendarDebugSplitLayout
        var stack: NavigationStackID<CalendarTab> = .primary
        @Environment(CalendarHomeCoordinator.self) private var coordinator
        @Environment(CalendarPresentationContext.self) private var presentation

        private var navigation: CalendarNavigationContext {
            presentation.context(for: stack)
        }

        private var state: CalendarDebugSplitState {
            coordinator.debugSplitState(for: navigation)
        }

        var body: some View {
            @Bindable var state = state

            Group {
                switch layout {
                case .twoColumn:
                    NavigationSplitView(
                        columnVisibility: $state.columnVisibility,
                        preferredCompactColumn: $state.preferredCompactColumn
                    ) {
                        itemList(CalendarDebugSplitItem.allCases)
                            .navigationTitle(layout.title)
                    } detail: {
                        detail
                    }
                case .threeColumn:
                    NavigationSplitView(
                        columnVisibility: $state.columnVisibility,
                        preferredCompactColumn: $state.preferredCompactColumn
                    ) {
                        categoryList
                    } content: {
                        if let category = state.category {
                            itemList(category.items)
                                .navigationTitle(category.title)
                        } else {
                            ContentUnavailableView {
                                Label(CalendarStringKey.Debug.Split.chooseCategory, systemSymbol: .listBullet)
                            }
                            .toolbar { closeToolbar }
                        }
                    } detail: {
                        detail
                    }
                }
            }
            .environment(state)
        }

        private var categoryList: some View {
            @Bindable var state = state

            return List(selection: categorySelection) {
                Section(CalendarStringKey.Debug.Split.categories) {
                    ForEach(CalendarDebugSplitCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                Section {
                    Toggle(CalendarStringKey.Debug.Split.retainDetail, isOn: $state.retainsDetail)
                }
                CalendarDebugSplitControls(state: state, navigation: navigation)
                CalendarDebugSplitLayoutStatus(state: state)
            }
            .navigationTitle(layout.title)
            .toolbar { closeToolbar }
        }

        private func itemList(_ items: [CalendarDebugSplitItem]) -> some View {
            List(selection: itemSelection(in: items)) {
                Section(CalendarStringKey.Debug.Split.items) {
                    ForEach(items) { item in
                        Text(item.title).tag(item)
                    }
                }
                CalendarDebugSplitControls(state: state, navigation: navigation)
                CalendarDebugSplitLayoutStatus(state: state)
            }
            .toolbar { closeToolbar }
        }

        private var detail: some View {
            NavigationScopeView(context: navigation, presentation: presentation) {
                Group {
                    if let item = state.item {
                        CalendarDebugSplitDetailView(item: item, level: 0)
                    } else {
                        ContentUnavailableView {
                            Label(CalendarStringKey.Debug.Split.emptyTitle, systemSymbol: .listBullet)
                        } description: {
                            Text(CalendarStringKey.Debug.Split.emptyMessage)
                        }
                    }
                }
                .toolbar { closeToolbar }
            }
        }

        @ToolbarContentBuilder
        private var closeToolbar: some ToolbarContent {
            if presentation.isPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CalendarStringKey.Common.Action.close) { presentation.dismiss() }
                }
            }
        }

        /// Binding 的写入集中经过受控动作；不使用多个 onChange 互相同步 selection 和 path。
        private var categorySelection: Binding<CalendarDebugSplitCategory?> {
            Binding(get: { state.category }, set: { state.selectCategory($0, navigation: navigation) })
        }

        private func itemSelection(in items: [CalendarDebugSplitItem]) -> Binding<CalendarDebugSplitItem?> {
            Binding(
                get: { state.item.flatMap { items.contains($0) ? $0 : nil } },
                set: { state.selectItem($0, navigation: navigation) }
            )
        }
    }
#endif
