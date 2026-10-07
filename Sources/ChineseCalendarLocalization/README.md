# ChineseCalendarLocalization

全应用文案与本地化资源的基础模块，仅依赖 Foundation。由现有 `Sources/Package.swift` 定义，不依赖 Core、Data、Persistence、UI 或第三方库。

- `Strings/CalendarStringKey.swift` 是统一入口，功能扩展按功能、组件和用途拆分。
- `Resources/Calendar.xcstrings` 承载全部资源，table 为 `Calendar`；内部工厂集中指定本模块的 `Bundle.module`。
- 对外成员返回 `LocalizedStringResource`，动态函数接收 Foundation 值或基础参数；资源工厂保持模块内部可见。
- Core 和 UI 显式依赖并导入本模块。业务状态、错误或 SwiftData 类型如何选择文案，由调用模块负责；SwiftUI 控件适配留在 UI。
- 采用非 MainActor 默认隔离，Core 格式函数和 UI 都可以同步访问资源。

新增和维护文案遵循[文案与本地化规范](../../Docs/Conventions/Localization.md)。运行 `python3 Scripts/validate_localized_copy.py` 核对资源定义、catalog 和调用处残留；`ChineseCalendarLocalizationTests` 已接入 App scheme 的测试列表。
