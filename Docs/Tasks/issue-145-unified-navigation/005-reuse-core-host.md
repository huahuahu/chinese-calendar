# Issue #145：复用 Core 呈现宿主

- 日期：2026-10-07
- 来源：用户在确认两套宿主重复后，明确要求实施“Core 提供通用配置，业务 View 通过组合复用”的方案。
- 状态：实现及本轮定向验证完成，未提交。
- 范围：本次允许修改 Core 的呈现 View 与 API 文档，替代 [004](004-no-core-adjustment.md) 中业务自行递归呈现的方案；Core Router、节点状态及请求协调保持原样。

## 方案与验收

`NavigationPresentationNodeView` 增加 `providesNavigationStack` 策略（默认全部提供栈）和 `onChildDismiss` 回调（默认 nil）。每层递归传递这两个参数，策略按当前节点的 destination 求值；子模态关闭回调不承担根 presentation 关闭完成通知。

`CalendarPresentationNodeView` 组合该通用宿主，只提供业务容器策略、会话清理回调和原有 destination builder／数据环境。移除业务 View 中的 NavigationStack、sheet、full-screen 及自递归。根 `CalendarNavigationHost` 继续绑定根节点并完成根关闭协调。

- Core 原有默认调用保持兼容，Core 不依赖日历类型或 SwiftData。
- 年份选择器与下载详情继续由通用宿主提供单层导航栈。
- 演示父节点自带 Tab 栈，其子详情仍获得通用宿主的导航栈；关闭子详情保留父状态，重开正常。
- 验证 iOS 构建、现有导航／会话测试、格式与 lint，并检查年份选择器、演示嵌套及整树关闭的实际交互。
- 本轮证据与此前 `evidence/no-core/` 分开记录；旧证据不冒充本轮二进制验证。

## 结果

本轮仅修改两份 Swift 实现：`NavigationPresentationNodeView.swift` 和 `CalendarPresentationNodeView.swift`。前者实现可配置的导航栈与递归子关闭回调，后者组合前者；Core Router、节点类型、业务会话与数据注入代码未改。同步更新 Core README、导航规范和受影响的任务记录。

当前源码快照见 [source-sha256.txt](evidence/reuse-core-host/source-sha256.txt)：206 个 Swift 文件，清单 SHA-256 `021512fb057c49e0f2d6c7ae3654b08c7181467cdafc8006f29b69dfa73a6b0b`。与 no-core 清单逐项比较，仅上述两份实现不同。

- 原生 Xcode `RunSomeTests`：**36 passed，0 failed／skipped／not-run**，覆盖全部 Core 导航测试、CalendarRouter、呈现路由与 8 个业务会话测试；包含原有默认宿主初始化兼容检查。见[测试结果](evidence/reuse-core-host/tests.txt)。本次没有增加仅复述实现的测试，新增宿主组合由实际交互验证。
- 原生 `DeviceInteractionInstallAndRun` 构建、安装、运行成功，参数仅 `$(inherited)`，未加入临时验证代码。Debug 测试及 App 构建均成功；本轮未重跑 Release。
- 项目 `ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`，workspace `workspace-deC0lVsFJy`；配置指定的 Simulator `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0，竖屏。
- format、strict lint、`git diff --check` 均通过，见[检查摘要](evidence/reuse-core-host/format-lint.txt)。

### 本轮 Simulator 交互

2026-10-07 13:45–13:49，原生设备交互 session `Issue 145 Core Host Reuse`。点击基于最新 hierarchy hitPoint，并检查截图与操作后的层级；会话已结束。

| 场景 | 实际结果 | 证据 |
| --- | --- | --- |
| 普通模态与业务上下文 | 2026 picker 正确定位；选 2025 返回原页，重开时 2025 高亮，关闭正常 | [01](evidence/reuse-core-host/01-picker.png)、[02](evidence/reuse-core-host/02-selected-year.txt)、[03](evidence/reuse-core-host/03-picker-reopened.txt)、[04](evidence/reuse-core-host/04-picker-closed.txt) |
| 自带栈父页面与带栈子详情 | 演示选择 50%，打开子详情后有单层导航栏、显示 50%；关闭后父阶段保留，再开子详情正常 | [07](evidence/reuse-core-host/07-demo-50.png)、[08](evidence/reuse-core-host/08-child-detail.png)、[09](evidence/reuse-core-host/09-parent-preserved.png)、[10](evidence/reuse-core-host/10-child-reopened.txt) |
| 嵌套整树关闭 | 子详情可见时打开 `chinesecalendar://year/2024`，整棵 full-screen＋sheet 树关闭后进入 2024；日志 13:48:31.589210 Deferred、13:48:32.227756 Applied | [11](evidence/reuse-core-host/11-deep-link.png)、[日志](evidence/reuse-core-host/runtime-console.log) |
| 再次打开及无外层栈的关闭动作 | 重开演示回到新会话准备阶段，点击全屏“完成”回设置；完整数据仍已安装 | [12](evidence/reuse-core-host/12-demo-reopened.txt)、[13](evidence/reuse-core-host/13-fullscreen-dismissed.png) |

两套 Xcode MCP 均未暴露 URL opener，因此热深链接仅使用 `xcrun simctl openurl` 定向到上述 Simulator；其余构建与设备交互均使用原生 MCP。

本轮所见页面无重复导航栏、残留模态或崩溃。没有清除数据、访问网络下载或更改项目配置。没有重跑完整 227 项测试、Release、受控容器切换、真机或远端 CI；这些边界不使用此前 no-core 快照的证据补齐。未启动多 Agent review，也未提交或发布。
