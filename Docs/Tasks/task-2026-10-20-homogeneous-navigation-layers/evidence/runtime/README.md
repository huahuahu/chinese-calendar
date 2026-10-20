# 同构导航层 Simulator 运行记录

- 日期：2026-10-20，Asia/Shanghai。
- 工具：原生 Xcode MCP；执行前已独立读取 `device-interaction` skill。
- workspace：`/Users/tigerguo/.codex/worktrees/157b/Chinese-date/ChineseCalendar.xcodeproj`（`workspace-HszdYnMiww`）。
- scheme：`ChineseCalendar-iOS`。
- Simulator：`chinesedate iPhone 18 Pro Max (885f)`，`16A9CAA7-45CE-46D5-8915-F61531FC617C`。
- 已通过 `XcodeOpenWorkspace` 回读并核对 scheme、destination 与 `.xcodebuildmcp/config.yaml` 一致。
- 安装来源：主代理在本次子代理交互前完成 `DeviceInteractionInstallAndRun`；首个捕获时间为 22:04:56，PID 32476。根据主代理交接，这是 321 tests 对应阶段的安装包。本记录期间没有重装；后续恢复结构校验及根层恢复容器归属补丁不由这些截图证明，其最终自动测试另记。

## 已实际完成

| 步骤 | 结果 | 证据 |
| --- | --- | --- |
| 根层“设置 → 调试操作 → 导航测试 → Push 新测试页” | 到达导航测试页，作用域“设置”，当前层 Push 页数 1，页面 ID `C3D1D7CD-EAF4-438C-AEEC-59F88D592B9F` | [01-rootTest.png](01-rootTest.png) / [hierarchy](01-rootTest-hierarchy.txt) |
| 从该测试页选择“Sheet 打开主标签页” | 新 Sheet 显示主标签页，初始选中设置；设置导航栏有且仅有一个“关闭”按钮 | [02-sheetMain.png](02-sheetMain.png) / [hierarchy](02-sheetMain-hierarchy.txt) |
| Sheet 内切换“朝代” | Sheet 内显示朝代列表，朝代 Tab 选中，当前层“关闭”按钮一个 | [03-sheetHistory.png](03-sheetHistory.png) / [hierarchy](03-sheetHistory-hierarchy.txt) |
| Sheet 内选择“西汉” | 进入西汉详情，顶部返回按钮标记“朝代”，当前 Sheet 的朝代 Tab 选中 | [04-sheetHistoryPath.png](04-sheetHistoryPath.png) / [hierarchy](04-sheetHistoryPath-hierarchy.txt) |
| Sheet 内切回设置，再由“调试操作 → 导航测试 → 全屏打开主标签页” | 成功显示全屏主标签页的设置页，顶部“关闭”按钮一个；操作序列已达到 root → main-tabs Sheet → main-tabs fullScreen 三层 | [05-fullMain.png](05-fullMain.png) / [hierarchy](05-fullMain-hierarchy.txt) |

每次点击均依据前次 hierarchy 的 `hitPoint`；调试菜单行的外层 Button 中点首次无效，随后使用其嵌套 Button 的 hitPoint 成功打开，没有猜测截图坐标。截图中未观察到与此次新增入口相关的重叠、无法阅读或重复关闭按钮问题。

## 工具中断及证据边界

在全屏设置内继续打开导航菜单时，原会话 `Homogeneous Layers Verification` 返回 `Session not found. It may have already been closed, or the identifier is wrong`。之后只尝试一次接管同一 Simulator 上已安装的 App，创建 `Homogeneous Layers Finish`，没有重装 App。激活后显示日历根页，原层叠状态已不可用于关闭取证。第二个会话在设置导航菜单中再次返回同样错误，停止重试。

第二次接管是非 workspace 会话，没有可用于归因此状态重置的运行日志；原会话最后成功捕获仍报告 `Running`。已有日志包含 UIKit `cannot add handler ... dropping` 和 context-menu warning，未取得崩溃证据，因此不能把会话丢失或根页状态归因为本次代码 bug，也不能宣称运行稳定性完整通过。

两个会话均调用 `DeviceInteractionEndSession`，均回读 `Session doesn't exist anymore`。设备交互已释放，供主代理最终测试使用。

## XcodeBuildMCP fallback 补验

主代理完成最终原生 `RunAllTests`（325 passed）后，请求使用第三方 MCP 补关闭链路。原生会话已失败，按项目工具优先级切换 XcodeBuildMCP，并读取其官方 skill。

`session_show_defaults` 回读 project、scheme、Simulator 名称和 UUID 均与本文件顶部及 shared config 一致。仅以 `persist: false` 设置 bundle ID `com.tiger.suzhou.ChineseCalendar`，没有改配置文件。`launch_app_sim` 于 22:32 成功启动已安装 App，PID 40690；此轮没有构建或安装，因此不能额外声称该安装包已包含最终恢复补丁。

`snapshot_ui` 和 `screenshot` 正常。最新 snapshot 提供设置 Tab 的可点击目标 `e193`，两次 `tap({elementRef: "e193"})` 均报告成功（坐标 `x=306, y=885`），但每次重新捕获仍为日历页面：日历 `value=1`、设置 `value=0`，第二次前后 `screenHash=0knsim5`。因此最小关闭链路还没有开始；依据主代理的“第三方失败即记录并停止”要求，没有继续重试或使用直接命令绕过。此证据只能说明该操作路径未生效，不能据此确定是输入工具命中问题还是应用响应问题。

补充证据：[06-xcodebuildmcp-tab-tap-no-transition.jpg](06-xcodebuildmcp-tab-tap-no-transition.jpg)、[06-xcodebuildmcp-snapshot.json](06-xcodebuildmcp-snapshot.json)。结束时调用 `stop_app_sim` 停止本次启动的 App；没有保留原生设备交互 session。

## 本轮未验证

- 关闭最顶层后保留父层选择和路径；关闭父层回到根层原页面 ID。已确认根层初始状态，但没有关闭后的对照。
- Sheet 朝代详情路径在切换 Tab 后再次回来是否保留；模态 Tab 切换完全不改变根层状态。仅完成中间导航，没有最终回读。
- 主标签全屏内打开普通测试页 Sheet，以及普通页的 pop、sheet → fullScreen 递归、关闭重开。
- 下载预览容器的关闭按钮、子详情关闭。
- Deep Link 取消/批准、业务 Alert/FIFO 回归。
- 真机覆盖和最终恢复补丁的运行交互。

未触发真实清空已下载数据，未修改生产代码，未执行 commit。以上缺口不得用历史 #152 运行证据、编译成功或自动测试通过替代。
