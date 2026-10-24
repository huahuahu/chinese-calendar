# 外部导航入口与启动链接收敛：方案

- 关联：[Issue #174](https://github.com/huahuahu/chinese-calendar/issues/174)
- 状态：可执行
- 更新日期：2026-10-24
- 基线：同步后的 `origin/main`，`dc76f6b5`（已包含 #175 下载附件重构）

## 背景、目标与范围

`CalendarNavigationHost` 同时安装导航宿主和接收外部链接，以 Boolean 决定职责；Router 的冷启动方法则重复普通 Deep Link 提交。此次将外部入口统一到应用根 View 的 `.onOpenURL`，删除自定义启动参数通道。保持 URL 格式、确认与关闭协调、下载详情及错误提示行为。

依据：[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[导航规范](../../Conventions/Navigation.md) 的 NAV-02、NAV-03 和 NAV-05。

## 方案与决策

1. 删除共享宿主的 `handlesExternalNavigation` 参数、`.task` 和 `.onOpenURL`。宿主继续负责配置、环境和现有下载事件协调。
2. `ChineseCalendarRootView` 只通过 `.onOpenURL` 接收系统 URL，解析后交给现有 `@State` 持有的 `CalendarHomeCoordinator`。入口与 owner 留在数据库 identity 重建的内容之外。系统冷启动和运行中链接使用同一路径。保留负责准备数据库的 `.task`。
3. `CalendarHomeView` 是公开的日历根容器，当前仓库只有它自己的 Preview 与 `CalendarPageView` 的 Preview 调用，App 由 `ChineseCalendarRootView` 启动。按用户 diff 反馈删除 `CalendarHomeView` 的两个外部入口，只保留页面与导航宿主；外部链接统一由应用根接收。
4. 删除 Router 和 Coordinator 的 `openColdLaunchDeepLink`、一次消费标记、根 View 读取进程参数的 `.task`，以及 Parser 的启动参数数组重载。Coordinator 仅保留 `openDeepLink`，统一向 Router 传入 `confirmIfPresented: true`。
5. 路由映射测试直接提供 Deep Link，URL 解析测试覆盖合法、别名格式和无效输入。移除自定义启动参数与一次消费测试；验证后续系统链接仍可切换目标。保留真实宿主的确认等待及 dismiss 后应用测试。端到端冷启动／运行中验证通过系统 `openurl` 驱动，不再传 `--deep-link`。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| AC-01 | 共享宿主无外部入口开关、进程参数读取或 URL 接收 | 源码检索 |
| AC-02 | 合法系统 URL 跳转；不支持的 URL 不改变导航 | 自动测试、Simulator 系统 URL |
| AC-03 | 无自定义启动参数入口及消费标记；后续系统链接仍可切换导航目标 | 源码检索、自动测试；系统冷启动交互单独记录 |
| AC-04 | Router 仅保留统一 Deep Link 转换与提交路径 | 源码、路由测试 |
| AC-05 | 有模态时等待确认，取消保留路径，批准等实际关闭后跳转 | 现有 Core 合同与真实宿主测试、Simulator 交互 |
| AC-06 | 明确 CalendarHomeView 用途，仅应用根接收外部链接；普通宿主不依赖 Boolean | 调用点与源码核对 |
| AC-07 | 相关自动测试、格式和严格 lint 通过；交互证据分别记录 | 原生 Xcode MCP、项目检查脚本、结果记录 |

## 待定事项与后续调整

无目标或范围待定事项。验证受工具或运行环境阻碍时，在结果中明确记录，不能以构建代替交互证据。

2026-10-24 用户 diff 反馈调整：最初为了兼容公开容器的独立使用，在两个根 View 保留相同外部入口。用户指出重复后，核对到 `CalendarHomeView` 仅有 Preview 调用点，决定删除该处 `.task` 和 `.onOpenURL`，将外部入口集中在 `ChineseCalendarRootView`。此决定替代原方案第 3 项的兼容性保留，并对应调整 AC-06。

2026-10-24 验证环境调整：共享配置中的 Simulator 同时被另一工作区的构建／测试使用，原生交互也多次丢失 session。为取得独立证据，使用相同 runtime／机型的临时 Simulator，临时协调本工作区的工具配置；完成后恢复原配置并清理临时设备。此调整不改变产品行为或验收要求。

2026-10-24 用户进一步确认统一入口：删除整套 `--deep-link` 参数通道，正式构建和 DEBUG 构建均只接收系统 URL。此决定替代初版方案中保留启动参数、首次 nil 也消费一次的要求，以及 Issue 原文对应验收条件。旧参数验证仅作为历史证据保存；系统冷启动必须终止 App 后使用 `openurl`，不能沿用旧参数启动结果。
