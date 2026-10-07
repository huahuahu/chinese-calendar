# Issue #139：用户可见文案统一入口结果

- 关联：[Issue #139](https://github.com/huahuahu/chinese-calendar/issues/139)、[PR #144](https://github.com/huahuahu/chinese-calendar/pull/144)、[方案](000-plan.md)、[迁移清单](002-inventory.md)、[文案规范](../../Conventions/Localization.md)。
- 记录日期：2026-10-06。
- 代码状态（2026-10-06 验证时）：`codex/issue-139-localized-copy`，基线 `dc59e098715c7ae527b524da496856fc36f34985`，实现为下述工作区快照；提交与远程交付状态以关联 PR 为准。
- 验证快照：[implementation.sha256](evidence/implementation.sha256) 记录本次修改或新增的 96 个实现、模块说明、脚本及 CI 文件；该清单本身的 SHA-256 为 `37f2f365a10c59b3f5c012f98a21c8283ac6fa165fb4d0e99ffac98fc22a895c`。任务文档与截图不参与实现快照。

## 实际结果与决策

254 项文案统一通过 `CalendarStringKey` 访问，按 `Calendar`、`History`、`Settings`、`Store`、`Common` 及组件/用途分层。按用户确认的模块边界，新增现有 Package 内的 `ChineseCalendarLocalization` target，统一持有全部定义、`Calendar.xcstrings`、table 和自己的 `Bundle.module`；基础语言为 `zh-Hans`。Core 与 UI 显式依赖并导入本地化模块，没有新增独立 Package 或第三方依赖。

`ChineseCalendarLocalization` 只导入 Foundation，默认隔离为非 MainActor。`swift package --package-path Sources dump-package` 确认其项目/第三方依赖列表为空，Core/UI 的依赖关系正确。初版 Core/UI 各自持有资源的安排已被本方案替代；调整原因见[方案记录](000-plan.md#方案调整)。

静态成员与参数明确的函数返回 `LocalizedStringResource`，视图尽量保留资源到显示时解析。已有 String 格式 API 在明确边界解析；完整句式、标点、列表连接和数字格式集中管理。`LocalizedSymbolControls` 为 SFSafeSymbols 的 Label/Button 提供资源适配。干支、传统月日名、实体名称与来源原文保持原来的数据归属，例外逐项列在迁移清单。

`CalendarStoreErrorPresentation` 按 Persistence 错误、URL/Cocoa 错误及 HTTP 状态映射用户提示，启动、下载和清空失败不再直接展示底层诊断文字。`CalendarDatePrecisionPresentation` 在 UI 中将 Persistence 的日期精度转换为 `Common.DatePrecision` 资源；错误映射和 SwiftUI 控件适配同样保留在 UI，基础模块不接收业务模型。年号列表空状态只有统一资源中的一个定义来源，保留与 #119 相关的现有含义及布局。

新增 `Scripts/validate_localized_copy.py`，核对定义与 catalog 的 key、默认值、格式占位符、翻译注释，检查文案定义只导入 Foundation，并扫描生产 UI 中的中文、英文和插值字面量。已接入本地 CI 与 GitHub CI，维护规则已加入项目规范索引。资源测试迁入 `ChineseCalendarLocalizationTests`，UI 保留业务映射测试；新测试 target 已通过 XcodeGen 的既有 scheme 修补脚本接入 App 测试列表。

## 验证环境

- 原生 Xcode MCP 重新打开当前工作树的 `ChineseCalendar.xcodeproj`，scheme 为 `ChineseCalendar-iOS`，workspace 为 `workspace-G7bhTKV8ie`；构建工具为 Xcode 27.1 Beta。
- 测试与设备交互使用共享配置指定的 `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，运行系统为 iOS 27.0，工具列出的 SDK 为 iOS 27.1。
- `RenderPreview` 的实际渲染目标由工具返回为 iPhone Duo / iOS 27.1；下方 Preview 证据按这个实际目标记录，不混作指定 Simulator 的实跑证据。
- Simulator 原先已安装完整日期数据。本轮未清空、重新下载或替换该数据库。

## 验收证据

| Issue 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| 统一入口、清晰层级、集中目录 | 已验证 | Localization 的 `Strings` 目录；254 项定义与唯一 catalog 一一核对。 |
| 全量盘点、迁移及字面量例外 | 已验证 | [迁移清单](002-inventory.md) 包含页面、展示模型、错误、无障碍、调试页与保留原因。 |
| 固定及动态模板统一调用 | 已验证 | 生产 UI 扫描剩余 21 个字符串均属于明确例外；完整句式不在调用处手动拼接。 |
| key/default/comment/table/bundle/基础语言，App 与 Preview 显示 | 资源及部分实跑已验证，最终 Preview 失败 | 新 bundle 中真实打包资源及中/英/法 locale 回退测试通过；最终版本日历与设置实跑通过。结构迁移后的 Preview 两次均因 XCPreviewAgent 启动超时失败，不用迁移前截图代替新 bundle 的显示证据。 |
| 同语义复用、实体来源和模块边界 | 已验证 | Localization 无高层依赖；Core/UI 显式依赖 Localization，Persistence 不依赖 UI；业务映射保留在 UI，实体和原始来源数据未改动。 |
| 主要场景、动态参数、实际无障碍朗读、交互回归 | 部分验证 | 已有实跑与 Preview 证据见下；实际 VoiceOver 焦点移动和语音朗读尚未验证，不能据 AX 标签宣称此项全部通过。 |
| 构建、现有测试、残留扫描与动态格式验证 | 已验证 | 22:12 原生 `BuildProject(buildForTesting: true)` 成功；22:14 最终 `RunAllTests` 为 **213 passed / 0 failed / 0 skipped / 0 not run**，见[测试结果](evidence/test-results.txt)。SwiftFormat、严格 SwiftLint、资源/残留扫描与 `git diff --check` 均通过。 |
| 新增文案维护规则 | 已完成 | [本地化规范](../../Conventions/Localization.md) 已从 AGENTS、SwiftUI 规范与 Docs 索引链接。 |

新增测试覆盖真实打包 catalog、无翻译语言回退、历史年份不加千位分隔、0/50/100% 动态及静态百分比、嵌套资源、0/1/12 数量、日期精度/索引/范围、实体列表、无障碍模板，以及网络、权限、磁盘、版本、校验、HTTP 和未知错误映射。新增独立 UI 测试覆盖全部五种日期精度到资源的映射。213 项结果确实包含 `ChineseCalendarLocalizationTests`，并非遗漏新 target 后复用旧测试总数。

## 运行时与 Preview

### 最终基础模块版本

原生 `DeviceInteractionInstallAndRun` 使用最终实现成功构建、安装并启动 App，PID 为 26089。22:26 的日历、设置捕获均确认 App 为 `Running`；截图与 hierarchy 对应一致，未发现原始 key 或未替换参数。

- [日历截图](evidence/localization-calendar.png)：日历标题、今天、丙午年八月小、公历范围、农历月格、连续日序和日期网格显示正常。
- [设置截图](evidence/localization-settings.png)：颜色模式、跟随系统、完整日期数据状态、清空入口、两个下载调试入口与说明显示正常。
- 下载调试页点击后的原生捕获超时，结束 session 时返回 `Session doesn't exist anymore`。XcodeBuildMCP fallback 使用已有安装产物，可重新进入日历，但后续设置点击返回 `FAILED`；没有再次构建、清空数据或无限重试。
- 最终模块版本的固定 0% / 50% / 100%、动态下载进度、详情与关闭、秦朝无年号空状态未完成实跑复验。百分比资源与模板有最终版本测试证据，不能替代这些操作证据。

### 迁移过程证据

以下日历、历史、设置实跑和两张 Preview 截图采自结构迁移前的 Core/UI 资源版本。迁移保留这些文案与交互，但旧截图只作为迁移过程记录，不代表新 bundle 已在所有页面复验。

- 日历：年份选择器打开/关闭、2026 年丙午年、选中日详情与今天标记已检查；[选中日截图](evidence/calendar-selected-day.png) 保留数据层级与日期显示。
- 历史：朝代列表、西汉详情和帝王列表的名称、范围与计数已检查；[朝代计数截图](evidence/dynasty-list-counts.png) 包含公元前范围和 0/13/43 等数量。
- 设置：颜色模式、完整数据状态、清空入口、下载调试入口与说明已检查。未执行清空数据。
- Preview：[数据准备失败](evidence/preview-error.png) 验证错误标题、恢复提示与重试入口；[皇帝详情](evidence/preview-emperor.png) 验证名称、计数、分区标签与来源说明。Preview 仅证明已渲染内容，不代表按钮实点或实际朗读。

## 验证中发现的问题与剩余边界

固定下载调试阶段曾显示 `0%%`、`50%%`、`100%%`，原因是无插值 catalog 文字被当成格式模板转义。已改回单个 `%`，并同步校验脚本、规范及 `fixedDebugPercentagesKeepOnePercentSign` 测试；最终 213 项测试包含此回归测试。迁入基础模块前的修复版本已实跑确认这三个静态标题为单百分号，最终模块版本的下载页实跑仍受上述工具限制。

原生设备 session 中途两次报告 `Session not found`，对应操作不计为通过，也没有证据将其认定为 App crash。专项设备验证的完整本地报告和原始层级保存在已忽略的 `.output/issue-139/`；本文件仅保留确认结论与必要长期证据。

最终模块版本的错误页 Preview 尝试两次，均返回 `AppLaunchTimeoutError.Incomplete`：`XCPreviewAgent.app` 未能在 iPhone Duo / iOS 27.1 上于 15 秒内启动。工具实际选择的 Preview 目标与工作区 Simulator 不同；不能据此声称最终版本 Preview 通过，也没有证据将工具启动超时归因为资源迁移。

实际 VoiceOver 朗读、真机，以及所有字号/语言/方向组合未验证。错误映射通过最终版本测试，错误页和皇帝详情的 Preview 截图仅来自结构迁移前版本；没有通过破坏现有数据制造运行时失败。皇帝列表卡片原本为静态内容，未为本次文案工作增加导航。旋转后月份条位置曾有异常观察，竖屏重启恢复，尚未证明与文案迁移有关，本次不将其作为已修复问题。

上述验证未启动独立代码审查流程。实现完成与 Issue 全部验收通过分开记录，远程交付不覆盖本记录列出的验证边界。

## 2026-10-07：同步主分支后的交付验证

按用户要求创建 PR 并合并前，先将文案迁移提交为 `911a7914`，再合入主分支的日历宽度修复 `f3435352`，得到 `a828082cd518a2539de26a611a503fb791ee0890`。`CalendarPageView` 自动合并无冲突，核对确认同时保留统一文案入口、可用窗口宽度布局和上游新增 Preview。

该代码版本再次通过原生 Xcode MCP App/test build，以及 **213 passed / 0 failed / 0 skipped / 0 not run** 的完整测试。项目、scheme、Simulator 与上文共享配置一致；SwiftFormat、严格 SwiftLint、254 项资源校验、21 个剩余生产字符串检查及 `git diff --check` 再次通过，见[同步主分支验证摘要](evidence/main-sync-validation.txt)。此前的实现快照仍对应 2026-10-06 的版本，本轮证据以此处 commit 为准。

本轮没有重复设备交互或 Preview；上文未完成的验收仍保留。PR 关联 #139，不通过合并自动关闭仍有验证缺口的 Issue。

## 2026-10-07：远程 review 的列表语言修复

Copilot 在 [review comment](https://github.com/huahuahu/chinese-calendar/pull/144#discussion_r4202245591) 指出默认列表 locale 与资源 bundle 回退语言可能不一致。新增测试先复现：不传 locale 的生产入口返回 `洪武, 永乐, 宣德`，而中文资源需要 `洪武、永乐和宣德`；en-US、fr-FR 的资源回退用例均失败。这里的 locale 指测试中的资源参数，没有修改设备语言，也不把测试宿主行为宣称为所有 App 配置下的实跑结果。

`Common.List.names` 的默认 locale 改为资源包的 `preferredLocalizations`，仍保留显式 locale 参数；`EmperorCardModel` 的多个在位区间也统一经过该入口。Apple 文档说明 `Locale.current` 会考虑宿主 App 的可用语言，而 bundle 的 `preferredLocalizations` 根据该 bundle 的资源选择语言，因此不能以宿主的 locale 代替基础资源模块的选择。

修复后 App/test build、**216 项完整测试**、SwiftFormat、严格 SwiftLint 和资源扫描均通过，新增测试还覆盖皇帝多段在位区间的实际展示模型路径。源码快照、修复前失败及修复后结果见[列表语言验证摘要](evidence/list-locale-validation.txt)。该远程问题已修复并验证，原有 Preview 与交互缺口保持不变。

## 2026-10-07：翻译注释语境补全

[后续远程 review](https://github.com/huahuahu/chinese-calendar/pull/144#pullrequestreview-5436720676) 指出 176 项固定文案的注释只重复符号路径，未满足本地化规范的页面与用途要求。已逐项补充实际页面、状态、控件用途和必要领域含义，同步更新 Swift 定义与唯一 catalog 的注释；同时将迁移清单中残留的“两个 catalog”改为当前单一资源表。

资源校验新增对此类占位注释的拒绝规则：修复前实际报告 176 项错误，修复后 254 项资源及 21 个保留生产字符串全部通过；SwiftFormat、严格 SwiftLint、`git diff --check` 通过。结构化比较确认本轮 Swift 资源文件与 catalog 只改变翻译注释，所有 key、默认文案、翻译值、插值和执行逻辑均保持不变，因此复用上一轮 216 项本地测试的行为证据；PR 的最终 CI 状态以 GitHub 当前提交为准。
