#if DEBUG
    import Foundation

    /// 一次下载演示会话的身份，由该演示的场景页与详情页共享。
    nonisolated struct DownloadPreviewSessionID: Hashable, CustomStringConvertible {
        private let rawValue: UUID

        init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }

        var description: String {
            rawValue.uuidString
        }
    }
#endif
