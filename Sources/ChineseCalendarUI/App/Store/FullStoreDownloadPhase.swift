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
        case .preparingManifest: "准备下载"
        case .downloading: "下载文件"
        case .validating: "校验文件"
        case .installing: "安装数据"
        case .completed: "完成"
        }
    }
}
