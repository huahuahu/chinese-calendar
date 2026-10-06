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
            case preparing = "准备"
            case downloadStarted = "下载（0%）"
            case downloading = "下载（50%）"
            case downloadFinished = "下载（100%，尚未校验）"
            case validating = "校验"
            case installing = "安装"
            case completed = "完成"

            var id: Self {
                self
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
                Tab("进度场景", systemSymbol: .arrowDownCircle) {
                    NavigationStack {
                        scenarios
                            .navigationTitle("下载进度预览")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("完成", systemSymbol: .checkmark) {
                                        dismiss()
                                    }
                                }
                            }
                    }
                }

                Tab("切换检查", systemSymbol: .checkmarkCircle) {
                    NavigationStack {
                        Text("切换标签后，底部应保留当前进度。点击附件可查看完整说明。")
                            .padding()
                            .navigationTitle("切换检查")
                    }
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
                Section("字号") {
                    Picker("Dynamic Type", selection: $textSize) {
                        Text("默认").tag(DynamicTypeSize.large)
                        Text("加大").tag(DynamicTypeSize.xxxLarge)
                        Text("辅助功能最大").tag(DynamicTypeSize.accessibility5)
                    }
                }

                Section("固定下载阶段") {
                    ForEach(Stage.allCases) { candidate in
                        Button {
                            stage = candidate
                        } label: {
                            HStack {
                                Text(candidate.rawValue)
                                Spacer()
                                if stage == candidate {
                                    Image(systemSymbol: .checkmark)
                                }
                            }
                        }
                        .accessibilityAddTraits(stage == candidate ? .isSelected : [])
                    }
                }

                Section("完整阶段说明") {
                    ForEach(Stage.allCases) { candidate in
                        LabeledContent(candidate.rawValue) {
                            Text(candidate.progress.detail)
                        }
                    }
                }

                Section("检查方式") {
                    Text("向下浏览列表可收起标签栏，向上返回可展开。也可旋转设备，检查不同可用宽度。")
                    Text("这里只展示固定进度，不会下载或修改日历数据。")
                }
            }
        }
    }

    #Preview("底部下载进度") {
        FullStoreDownloadPreview()
    }
#endif
