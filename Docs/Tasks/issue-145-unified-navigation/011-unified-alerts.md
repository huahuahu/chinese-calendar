# 统一业务 alert 与导航协调

> 2026-10-19：Issue #151 将会话的生命周期布尔值收敛为枚举，方案与本轮结果见 [014](014-alert-session-state.md)。下文保留初次接入时的证据。

- 日期：2026-10-14；状态：实现完成，自动验证通过；Simulator 点击流程因自动交互不可用而未验证。
- 承接 [010](010-independent-stack-state.md)。用户已确认统一管理 alert，并采用“已有 alert 时等待，关闭后再处理导航”的默认策略。

## 方案

1. 每层以一个枚举保存直接呈现的页面模态或业务 alert。页面模态拥有下一层，alert 只保存 ID 和强类型路由数据，不创建导航栈。
2. Router、`NavigationPresentationContext` 和快照增加 AlertRoute 泛型；AlertRoute 声明业务 Action 类型。NavigationContext 仍只依赖栈状态，不增加呈现依赖。
3. 已有业务 alert 时，后续业务 alert 按顺序排队；外部导航保留最新请求及其确认要求。原提示处理完并关闭后，重新检查页面模态，按需要提示离开；业务按钮不会批准外部请求。
4. 离开确认和业务提示使用同一个 alert 宿主。通过 UIKit 原生 UIAlertController 和关闭完成回调串行展示，不叠加两个 alert、不使用固定延迟、不继承或修改系统 alert 的私有视图。
5. 呈现期间和业务动作处理期间阻止栈修改；回调用 ID 和原层对象校验。异步业务动作结束后才继续处理后续提示和导航。失效层的排队提示不会转移到新页面。
6. App 接入下载错误、清理数据确认及结果提示；设置页 Debug 菜单增加普通 alert、连续 alert、alert 期间跨 Tab 请求的可重复测试动作。
7. 业务 alert 路由可纳入 Core 数据快照；关闭动画、待执行请求和已批准操作不恢复。App 明确拒绝恢复临时业务提示及其消息会话。

## 验收

| 场景 | 预期 |
| --- | --- |
| 根层、sheet、full screen 展示业务 alert | 路由驱动，仅一个系统 alert，原栈不变 |
| alert 期间收到多个业务提示 | 原提示保留，后续提示按顺序展示 |
| alert 期间收到跨 Tab / Deep Link | 原路径不变；关闭完成后再处理；保留最新目标 |
| 模态上的业务 alert 结束 | 再显示离开确认；取消保留模态，同意等模态实际关闭后跳转 |
| alert 的业务按钮 | 按钮动作与 Deep Link 批准分开，最多执行一次 |
| 旧提示、旧 Context、关闭期间的新请求 | 不能误批准新请求或操作新层 |
| 快照 | 可序列化业务提示数据，拒绝恢复执行中的事务 |

验证遵循 [导航规范](../../Conventions/Navigation.md) 与 [Xcode 工作流](../../agent-workflows.md)。自动测试、构建、Simulator 交互分别记录；本轮不修改下载进度条。

## 结果

本轮以 [源码清单及 SHA-256](evidence/unified-alerts/source-manifest.json) 标识未提交工作区，对比实施前备份记录 46 个新增、修改或删除的源文件。没有提交或推送；原工作区已有改动继续保留。

- Core 的单个呈现状态包含页面或业务 alert；栈 `NavigationContext` 没有增加 AlertRoute 泛型或呈现依赖。
- 统一调用为 `presentation.present(.sheet(route))`、`.fullScreen(route)`、`.alert(alertRoute)`。原页面 `present(_:style:)` 与 `presentAlert` 便捷入口仍可用。
- 旧 `NavigationConfirmationHost` 已被统一 alert 宿主替代。UIKit completion 确认实际关闭，随后等待 `onAlertAction`；回调 ID 和一次性处理标记防止重复动作。
- 页面关闭、确认请求和业务提示共同遵守等待规则；嵌套子模态的关闭动画也会阻止父层提前显示确认。自定义确认取消后会继续处理已排队的提示。
- App 的下载错误、设置清理确认及结果提示已迁入 `CalendarAlert`。模态销毁时清理已丢弃的消息数据。
- 设置 → 调试 → 调试操作 → 导航测试，新增普通提示、连续两个提示、从提示按钮导航、提示期间请求历史跳转；同样可在测试页的 sheet／full screen 内操作。
- [Core README](../../../Sources/NavigationCore/README.md) 与[导航规范](../../Conventions/Navigation.md)已同步 API、提示串行顺序和快照边界。

### 自动验证

环境：原生 Xcode MCP，`ChineseCalendar-iOS`，`chinesedate iPhone 18 Pro Max (885f)`，Simulator ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。

| 检查 | 结果与证据 |
| --- | --- |
| `BuildProject(buildForTesting: true)` | 成功，无编译错误；2026-10-14 21:28 的最终逻辑版本 |
| `RunAllTests` | 21:37 完成，278 passed／0 failed／0 skipped／0 not run；[测试摘要](evidence/unified-alerts/tests.txt) |
| alert 专项 | 新增 15 个执行场景，包括 sheet/full screen 参数化测试、FIFO、最新请求的独立确认要求、异步动作期间等待、重复回调、失效 Context、快照、取消自定义确认及子模态关闭时序 |
| 格式检查 | `./Scripts/format.sh --check`：0/260 文件需要修改 |
| 严格 lint | `./Scripts/lint.sh`：249 文件，0 violations |
| 本地化 | `python3 Scripts/validate_localized_copy.py`：291 项资源通过 |
| 空白检查 | `git diff --check`：通过 |

单元测试通过手动报告生命周期事件验证状态机；不代表系统动画或按钮点击已通过。构建日志仍有原有测试 sysroot、AppIntents 元数据提取和 Debug SF Symbol 弃用等警告，本轮没有宣称零警告。

### Simulator 验证与边界

最终源码已通过原生 `RunProject(attachDebugger: false)` 启动并显示日历。原生会话多次返回 `Session not found`；XcodeBuildMCP 点击返回成功但画面不变；CUA 读取 Device Hub 成功，两次点击均返回 `-10005: noWindowsAvailable`。未能进入设置调试入口，全部 alert 点击场景保留为未验证，不能据此判断实现存在缺陷。

[交互报告、最后截图与 hierarchy](evidence/unified-alerts/runtime/report.md)记录实际尝试和限制。三个已知原生会话均已尝试结束，并返回不再存在。自动测试不替代这部分界面验收。

当前 UI 宿主针对 iOS 使用 UIKit；未验证 macOS、真机、VoiceOver、Dynamic Type 或清理真实下载数据。本轮不修改下载进度条，也不包含跨进程自动恢复。
