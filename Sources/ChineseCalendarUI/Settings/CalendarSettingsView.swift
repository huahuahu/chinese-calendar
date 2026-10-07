import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 显示在设置标签页中，用于管理外观与本地数据。
public struct CalendarSettingsView: View {
    private let coordinator: ChineseCalendarStoreCoordinator
    private let showsDoneButton: Bool

    @Environment(\.dismiss) private var dismiss
    @AppStorage(CalendarColorSchemePreference.storageKey)
    private var colorSchemePreference = CalendarColorSchemePreference.system
    @State private var isConfirmingClear = false
    @State private var resultMessage: SettingsResultMessage?
    #if DEBUG
        @State private var isShowingDownloadPreview = false
    #endif

    public init(coordinator: ChineseCalendarStoreCoordinator, showsDoneButton: Bool = true) {
        self.coordinator = coordinator
        self.showsDoneButton = showsDoneButton
    }

    public var body: some View {
        Form {
            Section(CalendarStringKey.Settings.Appearance.title) {
                Picker(CalendarStringKey.Settings.Appearance.pickerLabel, selection: $colorSchemePreference) {
                    ForEach(CalendarColorSchemePreference.allCases) { preference in
                        Text(preference.title)
                            .tag(preference)
                    }
                }
            }

            Section(CalendarStringKey.Settings.Data.title) {
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
                            Text(CalendarStringKey.Settings.ClearData.progress)
                        } icon: {
                            ProgressView()
                        }
                    } else {
                        Label(CalendarStringKey.Settings.ClearData.action, systemSymbol: .trash)
                    }
                }
                .disabled(coordinator.isClearingDownloadedData)
            }

            #if DEBUG
                Section(CalendarStringKey.Settings.Debug.title) {
                    Button(
                        CalendarStringKey.Settings.Debug.simulateDownload,
                        systemSymbol: .arrowDownCircle,
                        action: startSimulatedFullStoreDownload
                    )
                    .disabled(!coordinator.canStartSimulatedFullStoreDownload)

                    Button(CalendarStringKey.Settings.Debug.downloadPreview, systemSymbol: .eye) {
                        isShowingDownloadPreview = true
                    }

                    Text(CalendarStringKey.Settings.Debug.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            #endif
        }
        .navigationTitle(CalendarStringKey.Settings.title)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button(CalendarStringKey.Common.Action.done) {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog(
            CalendarStringKey.Settings.ClearData.confirmationTitle,
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button(CalendarStringKey.Settings.ClearData.action, role: .destructive) {
                clearDownloadedData()
            }
        } message: {
            Text(CalendarStringKey.Settings.ClearData.confirmationMessage)
        }
        .alert(
            resultMessage?.title ?? CalendarStringKey.Common.Value.empty,
            isPresented: resultMessageIsPresented,
            presenting: resultMessage
        ) { _ in
            Button(CalendarStringKey.Common.Action.ok, role: .cancel) {}
        } message: { resultMessage in
            Text(resultMessage.message)
        }
        .calendarColorSchemePreference()
        #if DEBUG
            .fullScreenCover(isPresented: $isShowingDownloadPreview) {
                FullStoreDownloadPreview()
            }
        #endif
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

    private var dataStatusTitle: LocalizedStringResource {
        if coordinator.fullStoreDownloadProgress != nil {
            return CalendarStringKey.Settings.Data.Downloading.title
        }

        switch coordinator.state {
        case .ready(_, .full, _):
            return CalendarStringKey.Settings.Data.Full.title
        case .ready:
            return CalendarStringKey.Settings.Data.Base.title
        case .starting:
            return CalendarStringKey.Store.Bootstrap.preparing
        case .failed:
            return CalendarStringKey.Settings.Data.Recovery.title
        }
    }

    private var dataStatusDetail: LocalizedStringResource {
        if coordinator.fullStoreDownloadProgress != nil {
            return CalendarStringKey.Settings.Data.Downloading.message
        }

        switch coordinator.state {
        case .ready(_, .full, _):
            return CalendarStringKey.Settings.Data.Full.message
        case .ready:
            return CalendarStringKey.Settings.Data.Base.message
        case .starting:
            return CalendarStringKey.Settings.Data.Preparing.message
        case .failed:
            return CalendarStringKey.Settings.Data.Recovery.message
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
                    title: CalendarStringKey.Settings.ClearData.successTitle,
                    message: CalendarStringKey.Settings.ClearData.successMessage
                )
            } catch {
                resultMessage = SettingsResultMessage(
                    title: CalendarStringKey.Settings.ClearData.failureTitle,
                    message: CalendarStoreErrorPresentation.message(for: error, operation: .clear)
                )
            }
        }
    }

    #if DEBUG
        private func startSimulatedFullStoreDownload() {
            coordinator.startSimulatedFullStoreDownload()
        }
    #endif
}

private struct SettingsResultMessage: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    let message: LocalizedStringResource
}
