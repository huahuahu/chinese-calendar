import Foundation

enum FullStoreDownloadPhase: Equatable {
    case preparingManifest
    case downloading
    case validating
    case installing
    case completed
}

struct FullStoreDownloadProgress: Equatable {
    let phase: FullStoreDownloadPhase
    let downloadProgress: Double?

    static let preparingManifest = Self(phase: .preparingManifest, downloadProgress: nil)
    static let validating = Self(phase: .validating, downloadProgress: nil)
    static let installing = Self(phase: .installing, downloadProgress: nil)
    static let completed = Self(phase: .completed, downloadProgress: 1)

    static func downloading(progress: Double?) -> Self {
        Self(phase: .downloading, downloadProgress: progress)
    }

    var fractionCompleted: Double {
        switch phase {
        case .preparingManifest:
            0.03
        case .downloading:
            0.05 + (boundedDownloadProgress ?? 0) * 0.82
        case .validating:
            0.9
        case .installing:
            0.97
        case .completed:
            1
        }
    }

    var title: String {
        switch phase {
        case .preparingManifest:
            "正在准备完整日历数据"
        case .downloading:
            "正在下载完整日历数据"
        case .validating:
            "正在校验完整日历数据"
        case .installing:
            "正在安装完整日历数据"
        case .completed:
            "完整日历数据已安装"
        }
    }

    var detail: String {
        switch phase {
        case .preparingManifest:
            "正在获取下载清单。"
        case .downloading:
            if let boundedDownloadProgress {
                "已下载 \(boundedDownloadProgress.formatted(.percent.precision(.fractionLength(0))))。"
            } else {
                "已连接下载源，正在计算文件大小。"
            }
        case .validating:
            "正在检查文件大小和校验和。"
        case .installing:
            "正在替换本地数据存储。"
        case .completed:
            "现在可以浏览每日干支和对应公历日期。"
        }
    }

    var systemImage: String {
        switch phase {
        case .preparingManifest:
            "doc.text.magnifyingglass"
        case .downloading:
            "arrow.down.circle"
        case .validating:
            "checkmark.shield"
        case .installing:
            "externaldrive.badge.checkmark"
        case .completed:
            "checkmark.circle.fill"
        }
    }

    private var boundedDownloadProgress: Double? {
        guard let downloadProgress else {
            return nil
        }

        return min(1, max(0, downloadProgress))
    }
}
