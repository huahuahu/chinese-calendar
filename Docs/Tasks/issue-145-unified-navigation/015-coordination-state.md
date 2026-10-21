# 导航请求协调状态

> 本文保留该子任务当时的范围及 361 项阶段验证。后续任务继续修改了相关源码；当前统一 PR 的完整范围、最终源码标识和验证结果见[整合记录](017-navigation-state-integration.md)。文中的“不提交”和“其他改动不属于本次交付”仅指当时阶段。

- 日期：2026-10-21
- 关联：[业务 alert 协调](011-unified-alerts.md)、[alert 会话状态](014-alert-session-state.md)、[导航规范 NAV-05](../../Conventions/Navigation.md#nav-05--关闭和外部导航协调)
- 范围：将 Router 的六项请求／关闭等待字段收拢为一个内部协调状态，保持现有导航行为和公开读取接口。

## 方案

`NavigationCoordinationState` 统一处理请求提交、确认／取消、根模态关闭后的请求领取，以及 alert 结束后的请求／关闭意图领取。Router 继续检查实际呈现树和生命周期，并执行关闭或导航副作用；状态不复制 `NavigationLayer` 的关闭标志或 alert 会话。

- 请求状态区分无请求、等待确认、等待模态关闭。等待关闭可以同时携带另一条待确认请求：已批准 A 与待确认 B 并存是合法状态，取消 B 不撤销 A。
- alert 后请求通过关联值枚举携带“已接受”或“重新评估是否需要确认”，不再分开保存可选请求和 Boolean。
- alert 后关闭意图区分无操作、指定节点集合、全部；全部覆盖节点集合。私有存储只通过状态操作变更，不构造空节点集合。
- `deferredRequest`、`pendingConfirmation`、`requestWaitingForAlert` 改为只读投影；保留确认 ID 去重／过期保护、已接受请求 latest-wins、真实关闭与异步动作完成门禁。
- 当前工作区另有导航命名与 primary 栈修改，本次仅增量修改请求协调区域，不提交、推送或更改 Git 状态。

## 验收

| 场景 | 预期 |
| --- | --- |
| 已接受 A、待确认 B 并存 | 根模态关闭前后批准或取消 B，均保留正确请求；取消 B 不撤销 A |
| alert 期间请求被替换 | 最新请求携带自己的确认要求，无旧 Boolean 残留 |
| alert 期间指定节点关闭与全部关闭交错 | 全部关闭覆盖指定节点；等待真实 alert 关闭／业务动作结束，重复完成不误关新页面 |
| 既有导航回归 | 过期确认、关闭幂等、队列串行、快照和 Context 隔离保持 |
| 工具验证 | 原生 Xcode iOS 测试、format 与严格 lint；交互验证独立记录 |

## 实际结果

已实现。新增 `NavigationCoordinationState.swift`，Router 及呈现 Context 的原有读写改为调用状态操作。三个公开属性保留只读读取；原有三个独立 Boolean／集合存储已移除。请求提交结果仍由 Router 转换成关闭或导航副作用，确认 ID 校验和真实关闭门禁沿用原入口。

新增 `NavigationCoordinationTests.swift`：确认／取消 × 根模态关闭前后共 4 个场景，alert 前后请求的确认策略共 4 个场景，以及全部关闭先于／晚于指定节点关闭共 2 个场景。旧确认重复操作、重复关闭和重新打开页面的保护也在这些场景中断言。既有 alert、Context、快照与 App 导航测试一并通过。

| 验证 | 结果 |
| --- | --- |
| 原生 Xcode MCP `RunAllTests` | 361 passed；0 failed／skipped／not run；本次新增 10 个展开场景全部通过 |
| `./Scripts/format.sh --check` | 290 文件，0 需格式化 |
| `./Scripts/lint.sh` | 279 文件，0 violations |
| `git diff --check` | 通过 |
| Simulator 手动交互、真机 | 本轮未执行；单元测试手动推进生命周期，不等同于系统动画和实际点击证据 |

验证环境：`ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`，`chinesedate iPhone 18 Pro Max (885f)`；Simulator ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。测试在 2026-10-21 19:26（北京时间）运行，包含 iOS 测试所需构建。未单独运行 Release 构建或远端 CI，未运行独立 review。

本轮为未提交工作区验证，包含实施前已有的 primary 栈／导航术语修改；它们不属于本次交付。六个协调相关源码／测试文件的 SHA-256 和工具结果见[验证记录](evidence/coordination-state/validation.json)。测试后仅补充文档与证据，未修改 Swift 源码。
