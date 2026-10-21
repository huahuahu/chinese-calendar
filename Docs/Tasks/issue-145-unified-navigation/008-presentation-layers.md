# `NavigationLayer` 与导航栈分离

> 后续调整：[009](009-separate-context-apis.md) 已接续本轮，移除栈上下文的呈现便利入口；以下保留本阶段决策与验证记录。

- 日期：2026-10-11；状态：实施完成，构建、自动测试及关键 Simulator 交互已验证。
- 用户确认：每个 `NavigationLayer` 只有一个可选的子模态，展示方式为 sheet 或 fullScreen；同层可以包含一个或多个独立导航栈。根层的多个 Tab 共享模态状态，模态内部也允许多个 Tab。
- 承接 [006](006-scoped-router-plan.md) 与 [007](007-debug-actions.md)，保留工作区已有实现及调试入口。本轮替代统一 context 中按 root／Tab／模态分支处理全部操作的结构。

## 实施方案

1. 将每层状态统一为独立栈集合、选中栈和一个可选 presentation；presentation 携带 destination、style、ID 及下一层状态。sheet/fullScreen 不再是两份可写状态。
2. `NavigationPresentationContext` 负责本层 present、自身 dismiss、确认和关闭完成；不提供 path/push/pop。每个栈的 `NavigationContext` 引用同层同一个 presentation context，提供该栈的 path/push/pop，并保留页面调用 present/dismiss 的便利入口。
3. 根呈现宿主接收 `rootPresentation`；Tab 栈和模态栈继续由 `NavigationScopeView` 承载。App 下载布局预览中的多个 Tab 接入同层栈上下文，作为模态多栈示例。
4. 保留 Deep Link 请求 ID、最前层确认、取消保留状态、根关闭完成后执行、失效 context 检查。快照覆盖每层全部栈及唯一子模态；恢复拒绝重复节点 ID 和忙碌状态。本项目尚未启用跨启动持久化，更新快照格式，不兼容本分支先前未发布格式。

## 验收

- 同层栈 path 独立，presentation context 对象相同；模态内多栈遵循相同规则。
- sheet/fullScreen 互斥；子层关闭保留父层所有栈；旧 context 无法修改重建的新层。
- 外部导航确认与关闭时序回归通过，快照往返保留嵌套层和多栈状态。
- App Debug/Release 构建、iOS 自动测试、格式与 lint。Simulator 交互结果与构建／测试证据分开记录；本侧边对话不操作主线程的设备验证 Agent。

## 结果

### 状态与 API

- 新增内部 `NavigationLayer`，根层和模态层使用相同的状态结构：`selectedStack`、`roots`、`paths`、唯一 `presentation`。节点保存 destination、style 和下一层；同层同时存在 sheet/fullScreen 在结构上无法表达。
- `rootPresentation` 替代 `rootContext`，不再包含隐式操作当前 Tab 的 push/pop。`NavigationContext` 只绑定一个栈，并引用该层共享的 `NavigationPresentationContext`；同层 context 的 `presentation` 是同一个实例。
- `dismiss()` 关闭当前所在模态及其后代；根层返回 false。父层明确关闭子模态使用 `dismissPresented(id:)`，系统绑定也经此入口写回，旧节点 ID 不能关闭新节点。`pop()` 始终只操作本栈。
- 普通模态默认使用 `.primary` 栈。多 Tab 模态使用 `.scope(...)` 和本层 `selectedStack`，宿主跳过额外包栈。`FullStoreDownloadPreview` 已把两个 Tab 接入同层 `NavigationScopeView`，并由当前层的附件打开子详情。
- `CalendarRouter` 移除对设置 Tab 的旧忽略分支，根接口和局部 context 对全部三个 Tab 读写同一份 path。
- 快照保存每层全部栈、选中栈和子模态。恢复后重建对象；旧层 context 不能通过相同 ID 取得新层的栈。临时业务会话的恢复拒绝规则保持。

本次替换了此前未发布的 Core API 和快照 JSON 结构，迁移点见 [Core README](../../../Sources/NavigationCore/README.md)。[导航规范](../../Conventions/Navigation.md)同步记录层与栈的归属。`001-result.md` 保留旧阶段证据，并链接本轮结果。

### 自动化与源码边界

项目 `ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`；Simulator `chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，native workspace `workspace-RrA5WV2tRC`。两个 MCP 的上下文均已按 `.xcodebuildmcp/config.yaml` 核对。

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Debug | 首轮原生 build-for-testing 通过；最终源码由 RunAllTests 重新构建测试，并多次 InstallAndRun 成功 | [验证元数据](evidence/presentation-layers/verification.json)与设备报告 |
| iOS 自动测试 | 22:12 最终测试 255 passed，0 failed/skipped/not-run；较 007 增加 10 个运行实例 | [测试结果](evidence/presentation-layers/tests.txt) |
| Release Simulator | XcodeBuildMCP compile-only 成功，127.736 秒，无报告 warning/error；原生工具不支持 configuration 参数，使用单次 `extraArgs: ["-configuration", "Release"]`，未修改 session defaults | [构建日志](evidence/presentation-layers/release-build.log) |
| 格式与 lint | SwiftFormat 242 个文件均不需修改；strict lint 231 个文件零问题 | [format](evidence/presentation-layers/format.txt)、[lint](evidence/presentation-layers/lint.txt) |
| 文案与差异 | 282 项本地化资源检查通过，`git diff --check` 通过 | [文案检查](evidence/presentation-layers/localized-copy.txt) |

新增测试覆盖：根 Tab 共用呈现对象而 path 隔离；模态内部多个栈与根同名栈隔离；两种 style 都遵守唯一子模态和等待关闭约束；多栈快照往返；旧 context 无法控制同 ID 恢复层；多 Tab 层的 Deep Link 确认与取消；App 三个 Tab 的根／局部接口一致性。已有关闭、确认替换、批准后新请求、根与子完成通知及业务会话测试全部保留通过。

[源码 SHA-256](evidence/presentation-layers/source-sha256.txt)覆盖 231 个 Swift 文件及 String Catalog，共 232 项；清单 SHA-256 为 `8026a53d2d767f42f3801d91cc45d152c2aaeb9304da59aeeff192025e136450`。本轮证据全部位于 `evidence/presentation-layers/`，不沿用 006／007 的交互通过结论。

### Simulator 交互

[独立设备报告](evidence/presentation-layers/runtime-report.md)及 01–18 截图／hierarchy 记录：

1. 设置打开下载布局预览，选择 50%，切换第二个 Tab，打开子 sheet；关闭后仍停在第二个 Tab，进度保留 50%；返回第一个 Tab 并关闭父模态，回到设置。
2. 设置栈 Push→再 Push→Pop，返回原页面 ID；从该页打开 sheet→子 full-screen→关闭子层，返回原 sheet ID。
3. 嵌套 full-screen 内继续 Push，触发模拟 Deep Link；取消保留同一页面 ID 和 path 页数。批准后关闭 sheet/full-screen 整树，转场完成后进入日历 Tab 的 2026 页面。

未修改设备已有完整日期数据；本轮所有设备会话已结束。多 Tab 模态的实际逐栈 Push 由结构测试覆盖，演示 UI 验证了选中 Tab、共享子模态及业务状态保持。本轮未重跑连续外部 URL 替换、交互式下滑关闭、真机、其他 OS／设备、横屏、VoiceOver、Release 入口可见性和跨启动自动恢复；后者仍未接入产品。上述边界不影响已列出的自动测试与本轮实际交互结论。

实现尚未提交或推送；没有创建 PR、修改远端 Issue 或操作父对话的设备 Agent。
