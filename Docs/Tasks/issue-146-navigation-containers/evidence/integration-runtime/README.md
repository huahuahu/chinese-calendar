# 合并集成后的 Simulator smoke 验证

- 日期：2026-10-21。
- 范围：PR #157 与 main / #156 集成后的有限运行验证，随后对导航环境注入修复进行复验。
- 环境：`chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27 Simulator，竖屏 440 × 956 点。
- 工具：原生 Xcode `DeviceInteractionSynthesize`；每次点击和滑动均依据最新 UI hierarchy 的 `hitPoint`，并读取操作后的层级及截图。
- 安装与构建由主 Agent 完成；本验证 Agent 未改源码、构建、安装、commit 或执行远程写入，也未下载或删除数据。

## 首轮：发现 push 崩溃

会话 `Issue 146 Runtime Check`，App PID `21266`。代码状态为 PR #157 与 main 合并的工作区，尚未加入后续 `NavigationScopeView` 环境注入修复。

1. 设置 → 调试操作 → 导航测试 → 两栏 → 以弹窗打开。
2. 点击真实列表行“对象一”，其最新 hitPoint 为 `{220.0, 261.8}`；正常进入详情，当前对象为“对象一”，Push 页数为 `0`。
3. 点击“查看下一层详情”，hitPoint 为 `{220.0, 311.8}`。
4. 原生工具返回 `applicationState: Crashed`，截图显示系统桌面；立即再次无交互 capture，仍返回 `Crashed`。

完整日志末尾为：

```text
SwiftUICore/Environment+Objects.swift:34: Fatal error: No Observable object of type NavigationContext<CalendarTab, CalendarDestination> found. A View.environmentObject(_:) for NavigationContext<CalendarTab, CalendarDestination> may be missing as an ancestor of this view.

The connection to the application standard output has been closed.
```

证据保留在 `01-two-column-initial-*`、`02-two-column-selected-item-one-*`、`03-two-column-push-crash-*`，每组包含完整截图、hierarchy 和原始日志。初态与对象详情未观察到文字重叠或不可读问题。调试操作外层行的 hitPoint 首次点击无反应，改用实时层级中内嵌按钮的 hitPoint 后打开菜单。

首轮因崩溃未继续检查重复选择、切换对象、关闭、三栏或嵌套容器。原会话后来失效，由主 Agent 新建复验会话。

## 修复复验：通过已覆盖的交互路径

新会话 `Issue 146 Context Fix`，App PID `23698`。主 Agent 在 `NavigationScopeView` 的 `navigationDestination` 返回页显式注入导航 Context 与同栈 presentation 后重新构建安装；App 层源码未改。复验对应基线 HEAD `e6d13c22b5cb2e9967995ce4cb7896a2f0d1b7dc` 加该未提交工作区修复，不能仅以 HEAD 代表验证版本。复验后读取的 `Sources/NavigationCore/SwiftUI/NavigationScopeView.swift` SHA-256 为 `6ee277889e1eaf42cf1e4876590b48f365ce78a2be5881d2457df7b34eef6ea1`。

| 步骤 | 实际结果 | 关键证据前缀 |
| --- | --- | --- |
| 两栏 Sheet，真实列表选择对象一后 push | 子详情第 1 层、对象一、Push `1`，应用保持 Running | [截图](04-fix-two-push-one-screenshot.png) · [hierarchy](04-fix-two-push-one-hierarchy.txt) |
| 再 push 一层 | 子详情第 2 层、Push `2` | [截图](05-fix-two-push-two-screenshot.png) · [hierarchy](05-fix-two-push-two-hierarchy.txt) |
| 点击导航返回 | 返回第 1 层、Push `1` | [截图](06-fix-two-pop-one-screenshot.png) · [hierarchy](06-fix-two-pop-one-hierarchy.txt) |
| 点击“再次选择当前对象” | 仍停留第 1 层、对象一、Push `1` | [截图](07-fix-two-reselect-preserves-one-screenshot.png) · [hierarchy](07-fix-two-reselect-preserves-one-hierarchy.txt) |
| 点击“选择下一个对象” | 对象二详情、Push `0`，旧路径清空 | [截图](08-fix-two-switch-clears-path-screenshot.png) · [hierarchy](08-fix-two-switch-clears-path-hierarchy.txt) |
| 点击“关闭当前模态” | 回到根设置页 | [截图](09-fix-two-closed-screenshot.png) · [hierarchy](09-fix-two-closed-hierarchy.txt) |
| 三栏以全屏打开，真实列表选择分类一 | 进入分类一的中间栏，显示对象一、对象二 | [截图](10-fix-three-category-screenshot.png) · [hierarchy](10-fix-three-category-hierarchy.txt) |
| 真实列表选择对象一 | 进入对象一详情、Push `0` | [截图](11-fix-three-object-screenshot.png) · [hierarchy](11-fix-three-object-hierarchy.txt) |
| push 下一层详情 | 子详情第 1 层、Push `1` | [截图](12-fix-three-push-one-screenshot.png) · [hierarchy](12-fix-three-push-one-hierarchy.txt) |
| 在已 push 的三栏详情页打开测试 Sheet | 显示独立模态作用域、Push `0`、新页面 ID | [截图](13-fix-nested-sheet-screenshot.png) · [hierarchy](13-fix-nested-sheet-hierarchy.txt) |
| 关闭子 Sheet | 返回父层“子详情第 1 层” | [截图](14-fix-nested-sheet-closed-screenshot.png) · [hierarchy](14-fix-nested-sheet-closed-hierarchy.txt) |
| 关闭三栏全屏模态 | 回到根设置页，应用仍 Running | [截图](15-fix-three-closed-screenshot.png) · [hierarchy](15-fix-three-closed-hierarchy.txt) |

每个复验前缀保存截图与完整 hierarchy。`fix-verification-states.json` 保存这些 capture 的原生 `applicationState`，全部为 `Running`；`fix-console-summary.txt` 保留关键日志摘录，没有命中 `Fatal error`。复验过程中进程始终为 `23698`，未发现新的崩溃、明显文字重叠或不可读布局。

控制台在切换设置和打开嵌套 Sheet 时记录了 `Update NavigationRequestObserver tried to update multiple times per frame.`；已保留摘录。这两次操作均完成，当前有限交互未观察到与该警告对应的功能失败。

## 覆盖边界和会话状态

修复复验覆盖两栏 Sheet 的首次与连续 push、返回、重复选择保路径、换对象清路径、关闭，以及三栏全屏的分类 → 对象 → 详情 → push、嵌套测试 Sheet 和父子模态关闭。

未验证混合 Tab、三栏切换分类的保留／清理策略、宽屏多栏、旋转、真机、全部递归容器组合或 Deep Link／Alert 的完整矩阵；这次 smoke 不代表全部验收通过。

18:06 完成交互后已向主 Agent 释放设备。`Issue 146 Context Fix` 当时仍可用、应用停在设置页，由主 Agent 负责关闭会话和后续自动测试。本 Agent 仅继续写本证据目录。

## 最终版本 smoke：混合 Tab 路径保留

2026-10-21 18:10–18:13，主 Agent 在最终代码完成 347/347 自动测试后重新构建安装，使用会话 `Issue 146 Final Smoke` 验证。验证 Agent 本身没有重跑这些自动测试。该版本增加 coordinator 按 navigation context 缓存调试选择状态；具体源码 SHA-256、基线 HEAD 和 capture 状态见 `final-smoke-manifest.json`，以工作区文件指纹识别本轮构建对应的代码状态。

从设置的导航测试菜单进入“混合 Tab”，实际完成：

1. 两栏 Tab：点击真实“对象一”列表行，再进入“子详情第 1 层”，显示对象一、Push `1`。
2. 切到三栏 Tab：点击真实“分类一”列表行，再点“对象一”，进入详情后 push 一层，显示对象一、Push `1`。
3. 切回两栏 Tab：仍显示对象一、“子详情第 1 层”、Push `1`。
4. 再切回三栏 Tab：仍显示对象一、“子详情第 1 层”、Push `1`。

本轮四个关键 capture 的进程均为 `37470`、状态均为 `Running`；未发现崩溃或明显布局问题。证据前缀依次为 `final-smoke-01-two-push-one`、`final-smoke-02-three-push-one`、`final-smoke-03-two-restored`、`final-smoke-04-three-restored`，每组保存完整截图和 hierarchy。`final-smoke-console-summary.txt` 保存关键日志筛选结果。

本轮重点是最终状态缓存补丁下的真实选择、push 和混合 Tab 往返保留；未重跑上轮两层 push／pop、关闭、嵌套 Sheet 全流程，也未补测关闭重开空态或三栏分类保留策略。18:13 已停止设备调用并将会话 key 交主 Agent 清理，未自行关闭或重启。

最终版本的直接证据链接：

| 步骤 | 截图 | 层级 |
| --- | --- | --- |
| 混合 Tab 两栏 push 1 | [截图](final-smoke-01-two-push-one-screenshot.png) | [hierarchy](final-smoke-01-two-push-one-hierarchy.txt) |
| 混合 Tab 三栏 push 1 | [截图](final-smoke-02-three-push-one-screenshot.png) | [hierarchy](final-smoke-02-three-push-one-hierarchy.txt) |
| 切回两栏保留路径 | [截图](final-smoke-03-two-restored-screenshot.png) | [hierarchy](final-smoke-03-two-restored-hierarchy.txt) |
| 切回三栏保留路径 | [截图](final-smoke-04-three-restored-screenshot.png) | [hierarchy](final-smoke-04-three-restored-hierarchy.txt) |

[最终源码与运行状态清单](final-smoke-manifest.json) · [最终控制台摘录](final-smoke-console-summary.txt) · [原始崩溃日志](03-two-column-push-crash-logs.txt)
