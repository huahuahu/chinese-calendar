import ChineseCalendarLocalization
import Foundation
import SFSafeSymbols

struct FullStoreDownloadProgress: Equatable {
    let phase: FullStoreDownloadPhase
    let downloadProgress: Double?

    static let preparingManifest = Self(phase: .preparingManifest, downloadProgress: nil)
    static let validating = Self(phase: .validating, downloadProgress: nil)
    static let installing = Self(phase: .installing, downloadProgress: nil)
    static let completed = Self(phase: .completed, downloadProgress: nil)

    private init(phase: FullStoreDownloadPhase, downloadProgress: Double?) {
        self.phase = phase
        self.downloadProgress = downloadProgress
    }

    static func downloading(progress: Double) -> Self {
        Self(phase: .downloading, downloadProgress: progress.isFinite ? min(1, max(0, progress)) : 0)
    }

    /// 只有文件传输阶段有百分比；构造下载状态时必须提供进度。
    var downloadFraction: Double? {
        downloadProgress
    }

    var detail: LocalizedStringResource {
        switch phase {
        case .preparingManifest:
            CalendarStringKey.Store.Download.Preparing.detail
        case .downloading:
            CalendarStringKey.Store.Download.Downloading.detail(progress: downloadFraction ?? 0)
        case .validating:
            CalendarStringKey.Store.Download.Validating.detail
        case .installing:
            CalendarStringKey.Store.Download.Installing.detail
        case .completed:
            CalendarStringKey.Store.Download.Completed.detail
        }
    }

    var systemSymbol: SFSymbol {
        switch phase {
        case .preparingManifest:
            .textPageBadgeMagnifyingglass
        case .downloading:
            .arrowDownCircle
        case .validating:
            .checkmarkShield
        case .installing:
            .externaldriveBadgeCheckmark
        case .completed:
            .checkmarkCircleFill
        }
    }

    func status(of step: FullStoreDownloadPhase) -> FullStoreDownloadPhase.Status {
        if phase == .completed || step.rawValue < phase.rawValue {
            return .completed
        }

        return step == phase ? .current : .pending
    }
}
