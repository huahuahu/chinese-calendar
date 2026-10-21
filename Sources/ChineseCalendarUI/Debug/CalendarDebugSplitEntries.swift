#if DEBUG
    import ChineseCalendarLocalization
    import SwiftUI

    struct CalendarDebugSplitEntries: View {
        @Environment(CalendarPresentationContext.self) private var presentation

        var body: some View {
            Section(CalendarStringKey.Debug.Split.title) {
                Button(CalendarStringKey.Debug.Split.ordinary) {
                    presentation.present(.debugNavigation(id: UUID()))
                }
                ForEach(CalendarDebugSplitLayout.allCases) { layout in
                    Menu {
                        Button(CalendarStringKey.Debug.Split.openSheet) {
                            presentation.present(.debugSplit(layout: layout))
                        }
                        Button(CalendarStringKey.Debug.Split.openFullScreen) {
                            presentation.present(.debugSplit(layout: layout), style: .fullScreen)
                        }
                    } label: {
                        Text(layout.title)
                    }
                }
                Button(CalendarStringKey.Debug.Split.mixedTabs) {
                    let id = UUID()
                    presentation.present(
                        .debugNavigationTabs(id: id), style: .fullScreen,
                        initialStack: .scope(.years),
                        rootDestinations: [.scope(.years): .debugNavigation(id: id)]
                    )
                }
            }
        }
    }
#endif
