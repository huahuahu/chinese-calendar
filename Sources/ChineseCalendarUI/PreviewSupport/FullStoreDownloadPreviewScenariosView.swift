#if DEBUG
    import ChineseCalendarLocalization
    import SFSafeSymbols
    import SwiftUI

    /// 下载演示的第一个 Tab 根页面；会话状态仍归 coordinator 所有。
    struct FullStoreDownloadPreviewScenariosView: View {
        @Bindable var state: FullStoreDownloadPreviewState

        var body: some View {
            scenarios
                .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.title)
                .navigationBarTitleDisplayMode(.inline)
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
#endif
