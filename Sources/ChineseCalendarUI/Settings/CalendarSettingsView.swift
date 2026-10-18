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
    @Environment(CalendarPresentationContext.self) private var presentation

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
                    presentation.present(.alert(.clearDownloadedData))
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
                    CalendarDebugActionsMenu(storeCoordinator: coordinator)

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
        .calendarColorSchemePreference()
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
}
