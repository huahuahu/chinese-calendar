# Issue #152：Destination 容器声明与层入口结果

> 2026-10-22 后续决策：[Issue #159／#158](../issue-159-navigation-runtime/000-plan.md) 删除完整导航树快照与恢复，正常初始化独立校验，并将 Context 缓存集中到每个 Router 的内部 Store。本文中的恢复设计与验证保留为当时记录；运行时 path、Tab 和模态状态保留的契约继续适用。

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #152](https://github.com/huahuahu/chinese-calendar/issues/152)、[后续多栏 #146](https://github.com/huahuahu/chinese-calendar/issues/146)
- 记录日期：2026-10-19
- 代码状态：`codex/issue-152-destination-containers`，实现基线为 `4f386d06d9a0e4b2b248ea83a3604dc08fc5ae1f`；Swift 文件指纹见 [source-manifest.json](evidence/source-manifest.json)。
- 实现完成，最终源码 300 项自动测试全部通过，Simulator 关键交互已验证；Preview 生成快照成功但画面不完整，完整视觉仍未验证。2026-10-20 整理为本地 Git 提交，未 push 或创建 PR。

## 实际结果与设计细节

- `NavigationDestination` 将 `providesNavigationContainer`、Core 的 `navigationContainer` 和 `allowedNavigationEntries` 放在路由数据上；删除宿主的容器判断转发。新 Bool 为 true 表示页面组织顶层容器，语义与旧 true 表示 Core 包栈相反。
- 根和模态共用 `NavigationLayerContent` 的入口承载逻辑。`NavigationRootView` 构建 App 根入口，`NavigationScopeView(stack:presentation:)` 从状态读取各栈根路由。普通 push 直接使用既有栈的页面映射。
- App `.root`、日历／历史／设置根页及下载预览两个 Tab 均有明确 Destination，由 `CalendarNavigationConfiguration` 的统一 builder 构建。底部附件继续通过 View 配置传递，不写入 Router。
- `NavigationLayer.route` 是层入口的唯一状态来源。节点 id/destination 与 `NavigationPresentationContext` 的 route/destination 从中投影；栈的 root/path 独立保存，push、切 Tab 和替换栈根均不更改层入口。恢复同 UUID 时仍检查层／栈对象身份。
- `NavigationSnapshot` 保存根入口，恢复前完整校验根、栈根、路径、模态及重复 ID，非法恢复不部分修改状态。App 额外要求三个根 Tab 齐全，并继续拒绝业务提示、年份选择及下载演示等临时会话。
- 普通根／模态入口自动成为其承载栈的初始根，只校验相应 `.root`／`.presentation` 权限；显式 Tab 根和替换栈根才要求 `.stackRoot`。普通根替换栈根后的快照可以恢复，层入口仍保留原值。
- 两栏／三栏仅有类型化声明，当前状态入口与恢复均拒绝未实现的 Core 容器。SplitView 状态、栏间联动、折叠与栏目呈现权限仍由 #146 实现。

本轮没有扩大到多栏实现或自动跨启动恢复。保留带 root 闭包的 `NavigationScopeView` 初始化器用于独立 Preview／测试；生产根与 Tab 已迁移到状态驱动的入口。

## 实施中发现并处理的问题

| ID | 问题与处理 | 状态与证据 |
| --- | --- | --- |
| DEST-FIX-01 | 统一 builder 给下载预览 Tab 根重复加上关闭按钮。通用关闭按钮仅用于允许 presentation 的普通页面，保留场景页原有完成按钮。 | 修复后 Simulator 只显示完成按钮；见 [运行报告](evidence/runtime/runtime-report.md)。 |
| DEST-FIX-02 | 模态关闭后 Context 失效，栈根读到 nil，旧构建触发缺根 precondition 崩溃。`NavigationScopeView` 仅对有效 Context 的缺根报错，关闭期间停止构建根页。 | 保留旧构建崩溃日志；修复后从第二 Tab 打开并关闭下载详情，回到原 Tab、保留 50% 进度且 App Running。 |
| DEST-FIX-03 | 普通根恢复曾要求栈根等于层入口，错误拒绝合法的栈根替换。恢复改为验证两者各自的入口约束，新增编码往返测试。 | 最终 300 项测试通过，包含栈根替换后的编码往返与入口权限测试。 |
| DEST-FIX-04 | 普通模态可把 selectedStack 改成没有页面的命名栈。普通模态只允许 primary，新增状态断言。 | 最终 300 项测试通过，包含普通模态拒绝命名栈选择的断言。 |

SwiftData 环境测试使用声明自带容器的探针，避免 `ImageRenderer` 不渲染 NavigationStack 的限制；保留 ModelContext、数据完整度、coordinator、Query 结果及呈现身份断言。它验证环境继承，不代替真实栈交互。

## 验收证据

最终测试环境为 `ChineseCalendar-iOS`、`chinesedate iPhone 18 Pro Max (885f)`、iOS 27.0 Simulator / iOS 27.1 SDK。原生 `RunAllTests` 于 2026-10-19 23:11 完成：**300 passed，0 failed，0 skipped，0 expected failures，0 not run**。计数、源码指纹及原始产物路径见 [final-tests.json](evidence/final-tests.json)，完整逐项结果已保存为 [final-tests-summary.txt](evidence/final-tests-summary.txt)。

最终源码已通过 `./Scripts/format.sh --check`（273 文件、0 需格式化）、`./Scripts/lint.sh`（262 文件、0 violations）和 `git diff --check`；文档本地链接检查无缺失。测试之后只收尾文档和验证证据，没有继续改动 Swift 源码。

运行交互与各轮构建边界见 [runtime-report.md](evidence/runtime/runtime-report.md)：`09`–`19` 来自修复构建，`20`–`26` 来自最终源码指纹构建，不能把所有交互都称为最终源码逐项重测。

| 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| DEST-01 | 已验证 | 最终根宿主 builder 测试、App Tab 根配置测试通过；构建及普通 push 交互通过，稳定画面未观察到重复导航栏。 |
| DEST-02 | 已验证 | 最终独立栈测试通过；最终 Simulator 根 Tab 路径保留、下载预览两个 Tab 和子详情关闭通过。下载 Tab 没有 Tab 内 push 控件，该项由结构测试覆盖。 |
| DEST-03 | 已验证 | 最终 `NavigationDestinationTests` 验证入口稳定、Tab 根／path 独立、重复呈现 UUID 不同。 |
| DEST-04 | 已验证 | 最终编码往返、恢复原子校验、同 UUID 旧 Context 保护、临时会话与不完整 App 根拒绝测试通过；最终子详情关闭回归正常。 |
| DEST-05 | 已验证 | 最终 alert／外部导航状态测试通过；修复构建的普通／嵌套模态、关闭再开、alert 排队和 Deep Link 取消／批准通过。最终构建补测 Alert 期间请求导航通过；Deep Link 使用 DEBUG 入口，未从 Safari 实际打开 URL。 |
| DEST-06 | 部分已验证；完整 Preview 视觉未验证 | README、导航规范和 Preview／示例完成迁移，构建通过。两次原生 Preview 均 `errors=[]`，但 iPhone Duo / iOS 27.1 快照不完整，重试近乎空白；未据此宣称视觉通过。 |

## 审查与剩余范围

本任务为实施，未执行 `review-changes` 的独立专项审查。源码自查、自动测试、Preview、Simulator 与真机证据分别记录；未运行真机验证。#146 的完整多栏能力仍未实现。

原生 Preview 两次选择了 iPhone Duo / iOS 27.1，快照没有完整显示模态内容；运行中的配置 Simulator 已实际验证下载页面和关闭路径，不用该运行结果替代 Preview 视觉验收。重试记录见 [28-native-download-preview-retry.json](evidence/runtime/28-native-download-preview-retry.json)。

运行日志仍有 `NavigationRequestObserver tried to update multiple times per frame`，本次验证未伴随流程失败或新崩溃；没有将此诊断记为已修复。未覆盖真机、横屏、Dynamic Type 全矩阵、系统交互式拖拽关闭和后台恢复，详见运行报告。所有设备交互会话已结束。
