import ChineseCalendarLocalization
import Foundation

/// 流程中的位置不代表耗时或完成百分比。
enum FullStoreDownloadPhase: Int, CaseIterable, Identifiable {
    case preparingManifest = 1
    case downloading
    case validating
    case installing
    case completed

    enum Status {
        case pending
        case current
        case completed
    }

    var id: Self {
        self
    }

    var title: LocalizedStringResource {
        switch self {
        case .preparingManifest: CalendarStringKey.Store.Download.Preparing.title
        case .downloading: CalendarStringKey.Store.Download.Downloading.title
        case .validating: CalendarStringKey.Store.Download.Validating.title
        case .installing: CalendarStringKey.Store.Download.Installing.title
        case .completed: CalendarStringKey.Store.Download.Completed.title
        }
    }
}
