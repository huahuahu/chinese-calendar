import Foundation

public extension CalendarStringKey.Common {
    enum List {}
}

public extension CalendarStringKey.Common.List {
    /// 实体名称保持原始值，默认跟随资源包实际选择的语言连接列表。
    static func names(_ values: [String], locale: Locale? = nil) -> String {
        let localization = Bundle.module.preferredLocalizations.first
            ?? Bundle.module.developmentLocalization
            ?? "zh-Hans"
        let locale = locale ?? Locale(identifier: localization)
        return values.formatted(.list(type: .and, width: .narrow).locale(locale))
    }
}
