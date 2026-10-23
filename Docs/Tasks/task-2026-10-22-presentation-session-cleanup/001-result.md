# 移除配置层关闭回调：结果

- 方案：[000-plan.md](000-plan.md)
- 日期：2026-10-22
- 后续方案：[Issue #165](../issue-165-presentation-ownership/000-plan.md)已替代本文的保留路由观察与集中字典清理设计，并进入工作区实施；新合同的真实关闭验证仍在进行。下文证据仅对应旧实现，不证明新方案通过验收。
- 代码状态：在已有未提交的导航结果及 alert 改动上增量实现；本次文件的 SHA-256 见 [source-manifest.json](evidence/source-manifest.json)，最终全量测试前后这些文件一致。

## 实际结果

删除 `NavigationHostConfiguration.presentationDidDismiss()`、默认实现、Core 对业务配置的调用以及 App 配置实现。Core 内部的真实关闭通知、队列推进和延迟导航继续自动执行。

`NavigationLayer` 保留关闭中的子树到动画实际完成；`retainedPresentationRoutes` 投影活动、排队和关闭中的模态身份，`retains(context)` 按原栈对象判断缓存是否仍需保留。`CalendarNavigationSessionCleanup` 位于稳定根宿主，观察呈现身份、alert 路由和业务会话登记；coordinator 按 sessionID 回收年份选择及下载演示数据，按栈对象回收分栏状态。默认入口的年份呈现被拒绝时也立即回收新会话。

排队 alert 的查询保持原有语义：所属活动页面关闭后，队列中的提示不再属于 `alertRoutes`。只有关闭中页面及其业务数据需要保留到实际完成。旧的“关闭开始时层对象立即释放”测试相应改为检查完成后释放，Context 仍在关闭开始时立即失效。

## 验收证据

原生 Xcode MCP，scheme `ChineseCalendar-iOS`，Simulator `chinesedate iPhone 18 Pro Max (885f)`、iOS 27.0。构建、全量及宿主专项结果见 [validation.json](evidence/validation.json)。

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| AC-01 | 已验证 | 配置中已无该方法及调用；原生 `BuildProject(buildForTesting: true)` 成功 |
| AC-02 | 已验证 | `NavigationRetentionTests`、`CalendarPresentationTests`、`CalendarSessionRetentionTests` 覆盖 sheet/fullScreen、子层和祖先关闭、动画期间保留及完成后释放 |
| AC-03 | 已验证 | 队列等待、根队列取消、祖先关闭丢弃队列、拒绝年份呈现均有测试；宿主测试覆盖下一轮界面更新前入队又取消 |
| AC-04 | 已验证 | 下载演示和分栏缓存释放有专项断言；现有 store identity、alert 与 Deep Link 回归通过 |
| AC-05 | 已验证（结构及宿主测试） | 使用实际 `UIHostingController` 与测试窗口挂载生产清理 modifier；等待可观察状态变化，不手动调用业务清理。Core 重复通知及失效父层通知测试通过 |

最终 `RunAllTests`：**415 passed，0 failed，0 skipped，0 notRun**。本次新增 12 个运行用例。`./Scripts/format.sh --check`、`./Scripts/lint.sh`（0 violations）和 `git diff --check` 通过。

## 验证边界

宿主集成测试验证 SwiftUI 订阅与自动清理链路；关闭完成由测试驱动 Core 入口。本轮没有手动执行 App 中的下滑关闭、视觉动画检查或真机交互，不将这些测试等同于完整交互验收。此处保留首次实现验证记录；用户随后授权将当前工作区全部改动合并提交。后续专项审查、主分支整合和 PR 验证见[整合结果](../task-2026-10-22-navigation-results/002-integration.md)。
