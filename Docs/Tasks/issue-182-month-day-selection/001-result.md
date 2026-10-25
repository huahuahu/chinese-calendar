# 月／日选择与基础数据年月浏览：结果

- 方案：[000-plan.md](000-plan.md)
- 工单：[Issue #182](https://github.com/huahuahu/chinese-calendar/issues/182)
- 日期：2026-10-24
- 代码状态：`codex/issue-182-month-day-selection` 未提交工作区

> 当前换库规则已按用户最新评论简化，见 [005-store-selection-simplification.md](005-store-selection-simplification.md)。下文前两轮换库恢复实现和验证仅保留为历史记录。

## 实际变更

CalendarSelection 只保存月／日枚举；Resolver、页面、年份选择器、当前月定位和 CalendarYearFeature 的换库恢复均使用该状态。基础数据的下载说明移到日格，日详情要求真实选中日。新增真实仅含年月的 Preview／截图夹具，并迁移原有测试到新的解析接口。

## 验收证据

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| AC-01 基础库当月首页 | 已验证 | 真实库当前九月、月序 27789；独立模拟器显示“丙午年 九月大”、年月控件及日格局部提示，真实仅年月夹具截图比较通过 |
| AC-02 基础年月导航 | 已验证 | 连续月序、年份 Binding 和边界过渡测试通过；模拟器验证前后月、选择 2025 年、十二月→次年正月、今天及月份条 |
| AC-03 完整日期与精确日 | 已验证（测试／截图） | Resolver 与历史边界测试、完整数据页面截图比较通过；本轮未完成真实下载后的点日交互 |
| AC-04 换库保留月份 | 部分验证 | 独立 base/full ModelContainer 的升级、降级、full→full 与落点保持测试通过；真实下载观察到 7% 且保持十月，因网络传输耗时未完成下载结束／清空后 UI 复验 |
| AC-05 未解析精确日 | 已验证 | 基础库精确日请求安装 full 后正确重试；不存在的日不回退月 |
| AC-06 年份会话 | 已验证 | 原有 Feature／Presentation 测试通过，包含旧 Binding 失效及嵌套选择器 |
| AC-07 工具验证 | 已验证 | 原生 Xcode 构建／运行、相关 iOS 测试、4 组 23 张截图比较，以及格式、严格 lint、本地化校验通过 |

首轮[测试摘要](evidence/validation/selection-tests.txt)记录 85 passed（参数化展开）。旧配置设备在验证过程中失效，因此不能把首轮结果声明为在该设备执行。创建独立 iPhone 18 Pro Max / iOS 27.0 模拟器 `Chinese-date Issue 182 (15bc)`，ID `BB854709-1C84-4E45-A6EB-63A6DD0EFF18`，更新共享配置并重新核对目标后，[复验摘要](evidence/validation/selection-tests-dedicated-simulator.txt)记录 71 passed、0 failed、0 skipped；此轮工具将参数化案例合并展示，包含所有选择解析、8 项换库测试、年份会话及 Core 用例。两轮请求相同的 70 个测试标识。XcodeGen 已重新生成工程以纳入新增测试文件，没有手改生成的 project.pbxproj。

[截图比较](evidence/validation/snapshot-comparison.txt)为 4 passed、0 failed，覆盖 23 张 PNG。通过独立录制 scheme 更新后，只保留 `calendar-base-data.phone.png` 的预期变化；其余录制产生的 PNG 变化恢复原基准，比较仍全部通过。录制过程的“Record mode is on”属于 SnapshotTesting 写入基准时的预期失败，最终验收依据为随后 `record: .never` 的成功比较。

[格式检查](evidence/validation/format.txt)：362 文件均无需格式化；[严格 lint](evidence/validation/lint.txt)：349 文件、0 violations。本地化脚本核对 337 项资源通过。

## 运行与工具边界

原生 DeviceInteraction session 跨调用丢失，交互按规则回退 XcodeBuildMCP。随后确认旧配置的设备 UUID 已不在 Simulator 列表、设备目录也已不存在，而 Xcode 自动改选其他机型；前两轮旧 UUID 截图不能对应本次运行，已排除出行为结论，并撤回旧 framework 的根因猜测。两种 MCP 都没有创建 Simulator 的操作，因此用 `xcrun simctl create` 创建本任务独立设备，再通过原生 MCP 构建运行。真实首屏及所有基础年月导航均成功。详细操作和未验证边界见[运行记录](evidence/runtime/runtime-results.md)。

本次没有请求专项 review，也未提交、推送或合并。工单保持打开，后续验收状态随真实结果更新。

## 2026-10-25 后续调整

当前月定位改用真实月长累计区间；详见[月长补充方案](003-month-daycount-plan.md)及[本轮结果](004-month-daycount-result.md)。本页原有运行证据仍对应此前实现。

## 2026-10-25 交付复验与评论处理

交付分支 `codex/issue-182-month-day-delivery` 基于最新 `main` 的 `e0723aea`。此前本地环境与模拟器修复已在 main，本次 PR 聚焦 Issue #182 及已接受的真实月长补充。

两条评论均已处理：累计区间类型改名为 `LunarMonthDateIndex`，不再暗示完整 Calendar 能力；Resolver 的 `month(for:)` 和 `yearNumber(for:)` 输入改为非空选择，未选择状态由调用方处理，数据不存在时仍可返回 nil。文件、测试及调用点同步更新。

本轮完整 iOS 测试 539 项通过。随后为兼容格式与 lint，将年入口的可选月份查询改写为 `Optional.flatMap`，最终源码的 Resolver 定向复验 19 项通过；4 组、23 张快照比较全部通过。SwiftFormat（363 文件）、SwiftLint（350 文件零违规）、335 项本地化资源及 919377 条 JSONL 校验通过。实际生产 `LunarMonthDateIndex` 逐日核对全部 884256 天与 29944 个月，无差异。数据独立检查确认基础 SQLite 完整、所有月份字段与导入文件一致，manifest identity 匹配。

合并前使用 review-changes 完成领域、UI、数据三个独立 lane 审查，并对最后的 Resolver 表达调整定向复审，未确认需要修正的缺陷。原始分工报告位于本地 `.output/reviews/20261025-issue182-pr/`；可携带的检查摘要与源文件 SHA-256 见 [pr-verification.json](evidence/validation/pr-verification.json)。

本轮未补做真实 full 下载完成后的点日、清空后的 UI 恢复，因此 AC-03／AC-04 的相应交互项继续保持未完成，Issue #182 保持打开；自动测试和快照不替代这些证据。基础库快照直接注入月份，仅证明渲染，不作为 `.today` 运行链的证明。远程 full SQLite 仍未重建或发布。远端 PR 与 CI 状态以 GitHub 当前记录为准。

## 2026-10-25 删除换库恢复逻辑后的最终状态

按用户最新评论删除 `StoreSelectionRestoration`、临时恢复字段、换库前月份查询与换库后恢复分支。现有失效入口只清空选择、重置初始解析标记，并继续使旧年份选择器失效；新库连接后重新解析原始 landing。同库刷新保留当前选择，精确日缺失时不回退到月份。原 AC-04 的跨库保留位置要求已由 [005 补充](005-store-selection-simplification.md) 替代。

调整 base→full、full→base、full→full 及同库刷新测试；增加清空完整数据后精确日入口保持不可用的回归，更新旧 Binding 失效断言。最终完整 iOS 测试 **540 passed，0 failed/skipped/notRun**；SwiftFormat 363 文件与 SwiftLint 350 文件零违规。专项领域／生命周期审查完成，未确认需要修正的缺陷。详见 [最终验证摘要](evidence/validation/pr-simplification-verification.json)。

此前 4 组／23 PNG 本地快照结果对应删除换库恢复前的源码；本轮没有修改 View 或快照源文件，远端 CI 将对最终 PR 提交重新比较。真实下载完成后的点日与清空后的页面重新定位尚未补做 UI 端到端复验；已撤销的“换库保留原浏览月份”不再作为当前验收要求。远程 full SQLite 未发布。
