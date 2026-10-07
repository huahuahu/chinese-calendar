import Foundation

/// 全应用的文案入口；资源与格式模板由基础本地化模块统一管理。
public enum CalendarStringKey {
    public enum Common {}
    public enum Calendar {}
    public enum History {}
    public enum Settings {}
    public enum Store {}

    static func resource(
        _ key: StaticString,
        defaultValue: String.LocalizationValue,
        comment: StaticString
    ) -> LocalizedStringResource {
        LocalizedStringResource(
            key, defaultValue: defaultValue, table: "Calendar",
            bundle: .atURL(Bundle.module.bundleURL), comment: comment
        )
    }
}
