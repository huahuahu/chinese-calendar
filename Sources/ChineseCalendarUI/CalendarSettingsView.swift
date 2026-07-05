import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

public struct CalendarSettingsView: View {
    private let coordinator: ChineseCalendarStoreCoordinator
    private let showsDoneButton: Bool

    @Environment(\.dismiss) private var dismiss
    @AppStorage(CalendarColorSchemePreference.storageKey)
    private var colorSchemePreference = CalendarColorSchemePreference.system
    @State private var isConfirmingClear = false
    @State private var resultMessage: SettingsResultMessage?

    public init(coordinator: ChineseCalendarStoreCoordinator, showsDoneButton: Bool = true) {
        self.coordinator = coordinator
        self.showsDoneButton = showsDoneButton
    }

    public var body: some View {
        Form {
            Section("外观") {
                Picker("颜色模式", selection: $colorSchemePreference) {
                    ForEach(CalendarColorSchemePreference.allCases) { preference in
                        Text(preference.title)
                            .tag(preference)
                    }
                }
            }

            Section("数据") {
                VStack(alignment: .leading, spacing: 6) {
                    Label(dataStatusTitle, systemSymbol: dataStatusSystemSymbol)
                        .font(.headline)
                    Text(dataStatusDetail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Button(role: .destructive) {
                    isConfirmingClear = true
                } label: {
                    if coordinator.isClearingDownloadedData {
                        Label {
                            Text("正在清空")
                        } icon: {
                            ProgressView()
                        }
                    } else {
                        Label("清空已下载数据", systemSymbol: .trash)
                    }
                }
                .disabled(coordinator.isClearingDownloadedData)
            }
        }
        #if os(iOS)
        .navigationTitle("设置")
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        #endif
        .confirmationDialog(
            "清空已下载数据？",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("清空已下载数据", role: .destructive) {
                clearDownloadedData()
            }
        } message: {
            Text("这会取消正在进行的完整数据下载，删除下载缓存，并恢复到内置基础日历数据。")
        }
        .alert(resultMessage?.title ?? "", isPresented: resultMessageIsPresented, presenting: resultMessage) { _ in
            Button("好", role: .cancel) {}
        } message: { resultMessage in
            Text(resultMessage.message)
        }
        .calendarColorSchemePreference()
    }

    private var resultMessageIsPresented: Binding<Bool> {
        Binding(
            get: { resultMessage != nil },
            set: { isPresented in
                if !isPresented {
                    resultMessage = nil
                }
            }
        )
    }

    private var dataStatusTitle: String {
        if coordinator.fullStoreDownloadProgress != nil {
            return "完整数据下载中"
        }

        switch coordinator.state {
        case .ready(_, .full, _):
            return "已安装完整日期数据"
        case .ready:
            return "正在使用内置基础数据"
        case .starting:
            return "正在准备日历数据"
        case .failed:
            return "日历数据需要恢复"
        }
    }

    private var dataStatusDetail: String {
        if coordinator.fullStoreDownloadProgress != nil {
            return "清空会取消当前下载，并删除已经保存的临时文件。"
        }

        switch coordinator.state {
        case .ready(_, .full, _):
            return "清空后会回到基础数据，日级记录需要重新下载完整数据后才能浏览。"
        case .ready:
            return "没有已安装的完整日期数据；仍可清理未完成的下载缓存。"
        case .starting:
            return "日历数据准备完成后可以清理下载缓存。"
        case .failed:
            return "可以尝试清空下载数据并恢复内置基础数据。"
        }
    }

    private var dataStatusSystemSymbol: SFSymbol {
        if coordinator.fullStoreDownloadProgress != nil {
            return .arrowDownCircle
        }

        switch coordinator.state {
        case .ready(_, .full, _):
            return .externaldriveFill
        case .ready:
            return .externaldrive
        case .starting:
            return .hourglass
        case .failed:
            return .externaldriveBadgeExclamationmark
        }
    }

    private func clearDownloadedData() {
        Task {
            do {
                try await coordinator.clearDownloadedData()
                resultMessage = SettingsResultMessage(
                    title: "已清空",
                    message: "已删除下载数据，并恢复到内置基础日历数据。"
                )
            } catch {
                resultMessage = SettingsResultMessage(
                    title: "清空失败",
                    message: error.localizedDescription
                )
            }
        }
    }
}

private struct SettingsResultMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
