import ChineseCalendarLocalization
#if DEBUG
    import SFSafeSymbols
    import SwiftUI

    /// 使用真实 TabView 附件，固定各下载阶段以便检查布局和无障碍。
    struct FullStoreDownloadPreview: View {
        @Environment(\.dismiss) private var dismiss
        @State private var stage = Stage.preparing
        @State private var textSize = DynamicTypeSize.large
        @State private var isShowingDetails = false

        private enum Stage: String, CaseIterable, Identifiable {
            case preparing
            case downloadStarted
            case downloading
            case downloadFinished
            case validating
            case installing
            case completed

            var id: Self {
                self
            }

            var title: LocalizedStringResource {
                switch self {
                case .preparing: CalendarStringKey.Store.Download.Preparing.shortTitle
                case .downloadStarted: CalendarStringKey.Settings.Debug.DownloadPreview.downloadStarted
                case .downloading: CalendarStringKey.Settings.Debug.DownloadPreview.downloading
                case .downloadFinished: CalendarStringKey.Settings.Debug.DownloadPreview.downloadFinished
                case .validating: CalendarStringKey.Store.Download.Validating.shortTitle
                case .installing: CalendarStringKey.Store.Download.Installing.shortTitle
                case .completed: CalendarStringKey.Store.Download.Completed.title
                }
            }

            var progress: FullStoreDownloadProgress {
                switch self {
                case .preparing: .preparingManifest
                case .downloadStarted: .downloading(progress: 0)
                case .downloading: .downloading(progress: 0.5)
                case .downloadFinished: .downloading(progress: 1)
                case .validating: .validating
                case .installing: .installing
                case .completed: .completed
                }
            }
        }

        var body: some View {
            TabView {
                Tab {
                    NavigationStack {
                        scenarios
                            .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.title)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button(CalendarStringKey.Common.Action.done, systemSymbol: .checkmark) {
                                        dismiss()
                                    }
                                }
                            }
                    }
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.scenariosTab, systemSymbol: .arrowDownCircle)
                }

                Tab {
                    NavigationStack {
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.switchMessage)
                            .padding()
                            .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab)
                    }
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab, systemSymbol: .checkmarkCircle)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .calendarTabViewBottomAccessory(isEnabled: true) {
                FullStoreDownloadBottomProgressView(progress: stage.progress) {
                    isShowingDetails = true
                }
            }
            .dynamicTypeSize(textSize)
            .sheet(isPresented: $isShowingDetails) {
                FullStoreDownloadDetailView(progress: stage.progress)
                    .dynamicTypeSize(textSize)
            }
        }

        private var scenarios: some View {
            Form {
                Section(CalendarStringKey.Settings.Debug.DownloadPreview.sizeTitle) {
                    Picker(CalendarStringKey.Settings.Debug.DownloadPreview.sizePicker, selection: $textSize) {
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.defaultSize).tag(DynamicTypeSize.large)
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.largeSize).tag(DynamicTypeSize.xxxLarge)
                        Text(CalendarStringKey.Settings.Debug.DownloadPreview.accessibilitySize)
                            .tag(DynamicTypeSize.accessibility5)
                    }
                }

                Section(CalendarStringKey.Settings.Debug.DownloadPreview.stagesTitle) {
                    ForEach(Stage.allCases) { candidate in
                        Button {
                            stage = candidate
                        } label: {
                            HStack {
                                Text(candidate.title)
                                Spacer()
                                if stage == candidate {
                                    Image(systemSymbol: .checkmark)
                                }
                            }
                        }
                        .accessibilityAddTraits(stage == candidate ? .isSelected : [])
                    }
                }

                Section(CalendarStringKey.Settings.Debug.DownloadPreview.detailsTitle) {
                    ForEach(Stage.allCases) { candidate in
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
        FullStoreDownloadPreview()
    }
#endif
