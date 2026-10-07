import Foundation

public extension CalendarStringKey.Common {
    enum List {}
}

public extension CalendarStringKey.Common.List {
    /// 实体名称保持原始值，使用本地化的列表分隔符连接。
    static func names(_ values: [String], locale: Locale = .current) -> String {
        values.formatted(.list(type: .and, width: .narrow).locale(locale))
    }
}
