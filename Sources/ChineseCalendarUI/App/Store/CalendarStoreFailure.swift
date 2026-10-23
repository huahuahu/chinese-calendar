/// 提示恢复建议所需的错误类别；不保存底层 Error、数据库对象或已经解析的文案。
nonisolated enum CalendarStoreFailure: Hashable {
    case prepare
    case download
    case clear
    case missingContainer
    case missingResource
    case invalidManifest
    case timedOut
    case network
    case storage
    case permission
    case incompatible
    case expiredDownload
    case invalidFile
    case server(status: Int)
}
