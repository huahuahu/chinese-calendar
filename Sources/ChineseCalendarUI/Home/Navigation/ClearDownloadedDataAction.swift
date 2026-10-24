/// 清理下载数据的确认提示只允许清理或取消。
nonisolated enum ClearDownloadedDataAction: Hashable {
    case clear, cancel
}
