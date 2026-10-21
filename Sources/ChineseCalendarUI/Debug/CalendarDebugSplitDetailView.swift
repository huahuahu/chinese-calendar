#if DEBUG
    import ChineseCalendarLocalization
    import SwiftUI

    struct CalendarDebugSplitDetailView: View {
        let item: CalendarDebugSplitItem
        let level: Int
        @Environment(CalendarNavigationContext.self) private var navigation
        @Environment(CalendarDebugSplitState.self) private var state

        var body: some View {
            Form {
                Section {
                    LabeledContent {
                        Text(item.title)
                    } label: {
                        Text(CalendarStringKey.Debug.Split.selection)
                    }
                    LabeledContent {
                        Text(navigation.path.count, format: .number)
                    } label: {
                        Text(CalendarStringKey.Debug.Navigation.pathDepth)
                    }
                    Button(CalendarStringKey.Debug.Split.push) {
                        navigation.push(.debugSplitDetail(item: item, level: level + 1))
                    }
                }
                CalendarDebugSplitControls(state: state, navigation: navigation)
                CalendarDebugSplitLayoutStatus(state: state)
                CalendarDebugNavigationActions()
                CalendarDebugSplitEntries()
            }
            .navigationTitle(level == 0 ? item.title : CalendarStringKey.Debug.Split.level(level))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
#endif
