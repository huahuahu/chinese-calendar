# Issue #139：用户可见文案统一入口

## 目标与范围

对应 [Issue #139](https://github.com/huahuahu/chinese-calendar/issues/139)。迁移日历、历史、设置、下载、导航、展示模型、错误提示、无障碍和 App 内可访问的下载调试页；保持中文含义、历史数据来源及交互不变。年号列表空状态沿用当前文案与布局（关联 #119）。

## 方案

- `CalendarStringKey` 为唯一类型化入口，按功能、组件和用途分组。新增现有 Package 内的 `ChineseCalendarLocalization` 基础 target，统一持有入口、功能定义与资源，只依赖 Foundation。Core 与 UI 按需显式依赖本地化模块；不新增独立 Swift Package 或第三方依赖。
- 本地化模块统一管理 `Calendar.xcstrings`、table 与自己的 `Bundle.module`；基础语言为 `zh-Hans`。固定资源与带明确参数的动态函数返回 `LocalizedStringResource`。需要字符串的格式 API 在明确边界解析；视图和展示模型优先保留资源。
- 稳定语义 key、中文默认值、翻译注释集中维护。不同业务语义不因文字相同而合并；重复日期精度和公共动作按同一语义复用。
- UI 根据底层错误类型/代码映射提示；技术错误描述只用于诊断日志，未知错误提供集中定义的恢复提示。
- 数据模型日期精度到资源的选择、结构化错误到用户提示的映射和 SwiftUI 控件适配保留在 UI；基础本地化模块不接收 Persistence 或 UI 类型。
- 干支、农历月名/日名、闰/后和大小月等历法词汇是领域值；实体名称、来源文本、数据库/导航标识、内部日志、测试与开发者 Preview 样本保留，不将它们误作产品句式迁移。App 内的调试页属于产品文案。

依据：[领域语言](../../../CONTEXT.md)、[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[历史 Tab](../../history-tab-rewrite-requirement.md)。

## 验收与证据

1. 提交按模块/页面分类的迁移清单与例外，扫描所有 Swift 字符串、插值、拼接、错误透传和无障碍属性。
2. 验证资源 key/default/comment/catalog/table/bundle、动态数字/百分比/列表/历史纪元、错误映射及无翻译语言回退。
3. 使用当前工作树 Xcode 项目、`ChineseCalendar-iOS` scheme、共享配置的 `chinesedate iPhone 18 Pro Max (885f)` Simulator，运行构建及已有测试。
4. 检查日历、历史、设置、下载/错误/空状态的 Preview 和运行时显示；实际 VoiceOver 朗读单列证据，不以标签文本代替朗读验收。
5. 运行格式、严格 lint 和残留扫描；新增文案规范纳入 Docs 索引。

开始状态：`dc59e098`，工作区干净，分支 `codex/issue-139-localized-copy`。结果记录将包含具体执行环境、工作区快照及未验证项。

## 方案调整

2026-10-06：初版为了复用现有模块，将入口/日期资源放在 Core、页面资源放在 UI。用户指出统一文案应归基础模块，并明确同意迁移到 `ChineseCalendarLocalization`。当前方案据此将全部 254 项资源归入同一 target；职责边界和资源归属更明确，也满足 Core 与 UI 两个现有消费者的共享需要。
