#if DEBUG
    import ChineseCalendarLocalization
    import Observation
    import SwiftUI

    /// 下载演示的展示状态；呈现树由共享 Router 保存。
    @MainActor
    @Observable
    final class FullStoreDownloadPreviewState {
        let id = UUID()
        var stage = Stage.preparing
        var textSize = DynamicTypeSize.large

        enum Stage: String, CaseIterable, Identifiable {
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
    }
#endif
