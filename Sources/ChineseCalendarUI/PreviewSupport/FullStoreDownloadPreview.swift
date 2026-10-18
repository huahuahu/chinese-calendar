import ChineseCalendarLocalization
#if DEBUG
    import NavigationCore
    import SFSafeSymbols
    import SwiftUI

    /// 使用真实 TabView 附件，固定各下载阶段以便检查布局和无障碍。
    struct FullStoreDownloadPreview: View {
        @Environment(CalendarPresentationContext.self) private var presentation
        @Bindable var state: FullStoreDownloadPreviewState

        var body: some View {
            @Bindable var presentation = presentation
            TabView(selection: $presentation.selectedStack) {
                Tab(value: NavigationStackID<CalendarTab>.scope(.years)) {
                    NavigationScopeView(
                        context: presentation.context(for: .scope(.years)), presentation: presentation
                    ) {
                        scenarios
                            .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.title)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button(CalendarStringKey.Common.Action.done, systemSymbol: .checkmark) {
                                        presentation.dismiss()
                                    }
                                }
                            }
                    } destinationContent: { destination in
                        CalendarDestinationView(destination: destination)
                    }
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.scenariosTab, systemSymbol: .arrowDownCircle)
                }

                Tab(value: NavigationStackID<CalendarTab>.scope(.history)) {
                    NavigationScopeView(
                        context: presentation.context(for: .scope(.history)), presentation: presentation
                    ) {
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.switchMessage)
                            .padding()
                            .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab)
                    } destinationContent: { destination in
                        CalendarDestinationView(destination: destination)
                    }
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab, systemSymbol: .checkmarkCircle)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .calendarTabViewBottomAccessory(isEnabled: true) {
                FullStoreDownloadBottomProgressView(progress: state.stage.progress) {
                    presentation.present(.downloadPreviewDetails(sessionID: state.id))
                }
            }
            .dynamicTypeSize(state.textSize)
        }

        private var scenarios: some View {
            Form {
                Section(CalendarStringKey.Settings.Debug.DownloadPreview.sizeTitle) {
                    Picker(CalendarStringKey.Settings.Debug.DownloadPreview.sizePicker, selection: $state.textSize) {
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.defaultSize).tag(DynamicTypeSize.large)
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.largeSize).tag(DynamicTypeSize.xxxLarge)
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.accessibilitySize)
                            .tag(DynamicTypeSize.accessibility5)
                    }
                }

                Section(CalendarStringKey.Settings.Debug.DownloadPreview.stagesTitle) {
                    ForEach(FullStoreDownloadPreviewState.Stage.allCases) { candidate in
                        Button {
                            state.stage = candidate
                        } label: {
                            HStack {
                                Text(candidate.title)
                                Spacer()
                                if state.stage == candidate {
                                    Image(systemSymbol: .checkmark)
                                }
                            }
                        }
                        .accessibilityAddTraits(state.stage == candidate ? .isSelected : [])
                    }
                }

                Section(CalendarStringKey.Settings.Debug.DownloadPreview.detailsTitle) {
                    ForEach(FullStoreDownloadPreviewState.Stage.allCases) { candidate in
                        LabeledContent(candidate.title) {
                            Text(candidate.progress.detail)
                        }
                    }
                }

                Section(CalendarStringKey.Settings.Debug.DownloadPreview.instructionsTitle) {
                    Text(CalendarStringKey.Settings.Debug.DownloadPreview.instructions)
                    Text(CalendarStringKey.Settings.Debug.DownloadPreview.message)
                }
            }
        }
    }

    #Preview("底部下载进度") {
        FullStoreDownloadPreviewHost()
    }
#endif
