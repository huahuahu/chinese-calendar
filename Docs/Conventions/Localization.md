# 文案与本地化

适用于 App 定义的页面文字、展示模型、枚举名称、错误提示、无障碍文字和可从设置访问的调试页。实现与 review 使用同一规则。

## 入口与归属

统一通过 `CalendarStringKey.功能.页面或组件.用途` 访问，例如 `CalendarStringKey.History.ReignEraList.Empty.message`。先按业务语义找已有定义，新增时使用嵌套命名空间；层级深度以清晰表达归属为准。

- 根入口及全部功能文案：[ChineseCalendarLocalization/Strings](../../Sources/ChineseCalendarLocalization/Strings)。文件按功能/组件拆分，同一组件的子命名空间可用多个 extension 组织在同一文件；供其他模块使用的命名空间和成员公开。
- 唯一资源表为 `Calendar`，catalog 位于 [Resources/Calendar.xcstrings](../../Sources/ChineseCalendarLocalization/Resources/Calendar.xcstrings)。内部 `resource` 工厂集中指定 table 与本地化模块的 `Bundle.module`；业务调用处只访问成员，不传 key、table 或 bundle。
- `ChineseCalendarLocalization` 是现有 Swift Package 中的基础 target，只导入 Foundation，采用非 MainActor 默认隔离。Core 与 UI 显式依赖并导入它；本地化模块不能反向依赖 Core、Data、Persistence 或 UI。
- 基础模块的动态模板接收 String、数量、比例、Locale 或资源等基础参数。`ChineseDatePrecision` 到资源的选择留在 UI 的 `CalendarDatePrecisionPresentation`；错误映射与 SwiftUI 控件适配同样留在 UI，防止业务类型进入基础文案模块。

固定文字用返回 `LocalizedStringResource` 的静态计算属性；动态完整句式用参数明确的函数。名称说明用途，如 `title`、`message`、`subtitle`、`accessibilityLabel`。相同用途且语义相同的跨功能文字放在 `Common`；相同字面文字但语义不同的入口不强行共用。

## 资源与语言

key 使用稳定语义路径，首段与各层用 lowerCamelCase，例如 `history.reignEraList.empty.title`。改变文字时保留 key；改变语义时新增 key。Swift 默认文字、String Catalog 的 `zh-Hans` 值、翻译注释必须同步。基础语言为 `zh-Hans`，与 `Sources/Package.swift` 和 App 的 `project.yml` 一致。

catalog 的条目显式维护并标记 `extractionState: manual`：自定义资源工厂不依赖 Xcode 自动提取。`python3 Scripts/validate_localized_copy.py` 检查 Swift 定义与 catalog 的 key、默认值、格式占位符和注释，并检查文案定义只导入 Foundation；检查已接入本地 CI 与 GitHub CI。不能只更新其中一个位置。新增翻译时可以在 catalog 为有数量参数的完整句子增加 plural variations；简体中文目前无需按数量改变词形。

注释说明所在页面与用途；动态文案需按顺序说明每个参数的含义。不要把实体名、完整路径或错误诊断文本当成翻译 key。

## 调用与动态内容

视图直接传资源，例如 `Text(CalendarStringKey.Settings.title)`；新的展示模型优先携带资源并延迟解析。`LocalizedSymbolControls` 为 SFSafeSymbols 补充资源重载，保持 `Text` 的本地化上下文。

已有返回 `String` 的纯格式 API，以及混合来源数据/可选句子的展示边界，可以显式 `String(localized:)`；模板、前后缀、标点仍必须定义在统一入口中。不要在业务调用处把已翻译的半句话拼在一起。原始实体名称直接显示，围绕实体的完整句式通过参数传入。列表使用 `Common.List.names`，默认 locale 跟随资源 bundle 的 `preferredLocalizations`，使连接词与文案回退语言一致；显式指定 locale 时由调用者保证上下文一致。日期沿用有 locale/calendar/timeZone 的格式器。历史年份和连续索引不能添加千位分隔，资源使用 `.number.grouping(.never)`。

百分比资源接收 0...1 的数值，由模板使用 `.percent` 格式化。catalog 中没有插值的固定百分比保留单个 `%`；只有格式模板中的字面百分号才写成 `%%`。数量使用数值插值，避免提前转成字符串而失去 plural 信息。日期范围与精度模板也集中管理，不从枚举 `rawValue` 生成界面标签。

## 错误与例外

`CalendarStoreErrorPresentation` 在 UI 边界按错误类型、HTTP/URL/Cocoa 错误码选择 `Store.Error` 资源。未知错误按操作提供恢复提示。Persistence 的 `LocalizedError` 保留技术诊断信息供日志/工具使用，不能把 `error.localizedDescription` 直接传给 Alert 或错误页面。

干支、传统月名/日名、闰/后与大小月是领域词汇；实体名称、原始来源文本、日志、协议/数据库标识、测试样本、开发者专用 Preview 标题不是产品模板。空布局占位和纯数字显示不需要资源 key。App 名称 `Chinese Calendar` 是平台配置中的产品专名，保留在 `project.yml`/Info.plist。具体迁移例外见 [#139 清单](../Tasks/issue-139-localized-copy/002-inventory.md)。

残留扫描有明确例外，不能替代人工检查新增页面与动态拼接。验收同时覆盖资源打包、缺失语言回退、动态参数、App 与 Preview，以及真实 VoiceOver；无障碍标签文本正确不等于已经验证朗读。
