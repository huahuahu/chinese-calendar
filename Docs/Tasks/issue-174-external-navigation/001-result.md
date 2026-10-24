# 外部导航入口统一为系统 URL：结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #174](https://github.com/huahuahu/chinese-calendar/issues/174)
- 记录日期：2026-10-24
- 代码状态：`dc76f6b5` 上 `codex/issue-174-external-navigation` 的未提交修改。
- 最新决策：按用户后续反馈，删除自定义启动参数入口；该决定替代 Issue 初版保留启动参数一次消费的方案。

## 最终实现

唯一外部接入链路：系统 URL → `ChineseCalendarRootView.onOpenURL` → `CalendarDeepLinkParser.deepLink(from: URL)` → `CalendarHomeCoordinator.openDeepLink` → `CalendarRouter.openDeepLink`。系统可以在 App 未运行或已运行时交付 URL，不按进程启动状态划分业务入口。

- 应用根删除读取 `ProcessInfo.processInfo.arguments` 的 `.task`，保留准备数据库的 `.task`。
- Coordinator 删除 `openColdLaunchDeepLink` 和 `didOpenColdLaunchDeepLink`，仅保留统一链接处理，并继续要求模态离开确认。
- Parser 删除 `[String]` 启动参数重载；不再支持 `--deep-link`。两种 URL Scheme、年份／朝代／皇帝路径和月份参数格式保持不变。
- Router 删除重复的冷启动方法，继续使用原请求协调机制。
- `CalendarHomeView` 当前仅由两个 Preview 调用，只安装页面与导航宿主。它与共享 `CalendarNavigationHost` 均不接收外部 URL，也不通过 Boolean 选择入口职责。
- 删除旧启动参数与一次消费测试。统一验证无模态立即应用、有模态等待确认、实际关闭后应用、后续链接切回日历，以及合法和不支持的 URL。原参数测试涉及的别名 URL 格式改由直接 URL 测试保留。

## 验收与证据边界

| 验收项 | 当前结果 |
| --- | --- |
| AC-01 共享宿主职责 | 源码已核对：无外部入口 Boolean、进程参数读取或 URL 接收。 |
| AC-02 系统 URL | 最终快照的合法／无效 URL 解析与路由测试已通过。初版曾实际验证系统 URL 从唐跳秦，以及 unsupported URL 保持秦；系统接入代码本轮未改，但该交互不是最终快照重跑结果。 |
| AC-03 删除启动参数通道 | `Sources`、`Apps`、`Scripts`、scheme 中无 `--deep-link`、`openColdLaunchDeepLink`、旧标记或进程参数读取引用。后续系统链接导航测试已更新。 |
| AC-04 Router 统一提交 | 只保留统一 `openDeepLink` 请求路径。 |
| AC-05 模态确认与关闭 | 统一入口的真实宿主测试及 Core 取消／批准／关闭合同测试已通过。手工模态按钮交互未验证。 |
| AC-06 应用入口与 Preview | 外部入口仅位于 `ChineseCalendarRootView`；`CalendarHomeView` 和普通宿主不承接系统事件。 |
| AC-07 验证分列 | 本轮原生 Xcode 构建及 27 个测试用例通过，format、严格 lint、diff 和文档链接检查通过。详见[最终自动验证](evidence/unified-url-validation.md)。 |

最终源码快照 SHA256 为 `82212d18e07bc6234a78db45138014ef844aedbab4f315b1249bd516dfaee481`。测试使用 24 个标识，展开参数后共 27 个用例。临时测试配置已逐字恢复，未留下配置改动。

## 历史证据与剩余边界

[初版自动验证](evidence/automated-validation.md)的 40 项通过，以及[初版 Simulator 记录](evidence/device-interaction.md)，均对应删除启动参数前的源码快照，不能称为最终实现的完整验收。历史记录中的 `--deep-link` 启动截图不构成系统 URL 冷启动证据。

本轮不重跑 UI 交互：实际系统 URL 冷启动仍未验证；真实模态按钮的取消／批准也未验证。初版原生会话失效、共享 Simulator 并发和窗口点击失败的具体情况保留在历史记录中，不推断为本次产品缺陷。

未运行专项 `review-changes`；未执行真机验证、全量 CI、提交或远端 PR 操作。
