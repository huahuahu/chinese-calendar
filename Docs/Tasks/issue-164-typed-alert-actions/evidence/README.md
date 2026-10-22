# Issue #164：Simulator 实际交互证据

- 日期：2026-10-23，设备日志时间 06:50–06:55（+0800）。
- 代码：`5fc6a1043eebd119d25bd068a234abdaf95a7be4`。开始时为 `deced9a1` 加未提交实现；交互期间只将同一源码提交为上述 commit，没有改变安装的产品源码。
- 快照：排序后的 `Apps/`、`Sources/` 全部 323 个 Swift 文件（排除 `.build`），依次拼接路径、NUL、内容、NUL 的 SHA-256 为 `854d5ce74cd8d0a36759d18568a4b1d2c0804966961cdecb2b1d31ffb5bd69f7`；交互前后相同。
- 环境：`ChineseCalendar-iOS`，iOS 27.0 Simulator `chinesedate iPhone 18 Pro Max (885f)`，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，竖屏 440 × 956 pt。仅操作此任务专用 Simulator。
- 工具：原生 Xcode MCP `DeviceInteractionSynthesize`，session `Verify Typed Alert Actions Final`，workspace `workspace-edAhOBzbKD`。最新 App 由主 agent 安装运行，PID `54802`。
- 方法：每次点击使用最新层级的 hitPoint，随后同时检查截图、层级与进程状态。系统动画中的不一致截图重新捕获稳定画面。未修改产品代码，未用脚本直接驱动业务状态。
- 完整 37 次捕获及命令保存在本地忽略目录 `.output/issue-164-device/`。以下仅保留 8 张关键图及精简摘录。

## 实际结果

| 场景 | 实际操作与可观察结果 | 状态与证据 |
| --- | --- | --- |
| 普通通知 Action | 设置 → 调试操作 → 导航测试 → Push 新测试页 → 显示业务 Alert；出现“业务提示 1”，点击“好”（220, 564.7）。提示关闭后仍为设置栈 Push 1，页面 ID `9A5D9FF1-A7D5-4168-83A9-EFE7BD24143F` 未变。 | 通过；层级 05–07。 |
| 连续提示 | 点击“连续显示两个 Alert”（220, 848.2），先显示“业务提示 1”；点击“好”后显示“业务提示 2”；再次点“好”回原页。每次层级只有当前的一个 Alert。 | 通过；[提示 1](08-queue-first.png)、[提示 2](10-queue-second-stable.png)，层级 08–11；日志 `presentAlert applied → queued → resumePresentation applied`。 |
| 独立导航 Action 的取消 | 滚动后点击“从 Alert 按钮跳转”（220, 129.2），显示“前往历史页面？”，点击“取消”（220, 580.7）。仍留设置 Tab 和原滚动位置，无历史跳转。 | 通过；[导航提示](13-navigation-choice.png)，层级 13–14。 |
| 独立导航 Action 的执行 | 再次打开同一提示，点击“在历史 Tab Push 测试页”（220, 524.7）。提示关闭，历史 Tab（界面标签“朝代”）选中，测试页作用域“朝代”，Push 1，页面 ID `FB05F0F3-7788-4186-9EAD-CC004705AFDF`。 | 通过；[跳转结果](16-navigation-applied.png)，层级 16；日志先 `deferredUntilAlertDismisses` 后 `applied`。 |
| 模态外部请求与取消 | Sheet 打开测试页，记录模态 ID `C997E58C-04EE-4772-B99F-6390AE5C1DAD`、Push 0。点击“Alert 期间请求跳转历史”（220, 472.8）先显示业务提示 1；点“好”后才出现“离开当前页面？”。点“留在当前页面”（220, 580.7）并滚回顶部，仍是同一模态 ID、Push 0。 | 通过；[离开确认](21-leave-confirmation.png)、[取消保留模态](23-modal-identity-retained.png)，层级 18–23；日志为等待业务提示、等待确认、`cancelConfirmation applied`。 |
| 模态外部请求与继续 | 同一模态再次执行上述流程，在离开确认中点“关闭并前往”（220, 524.7）。模态关闭后，历史栈 Push 从 1 变成 2，新页面 ID `C273DD63-E7AB-47E9-A43D-FEEE1FDF7A8F`。 | 通过；层级 25–29；日志为 `deferredUntilPresentationDismisses → applyDeferredRequest applied`。 |
| 清空确认取消 | 回设置，状态为“已安装完整日期数据”；点击“清空已下载数据”（220, 479.5），再点“取消”（220, 592.7）。确认消失，仍显示“已安装完整日期数据”。 | 通过；[清空确认](32-clear-confirmation.png)，层级 31–33。 |
| 清空执行与结果通知 | 再打开确认，点击红色“清空已下载数据”（220, 536.7）。App 退出到 SpringBoard；连续两次工具状态均为 `Crashed`。未观察到可点击的成功结果通知。 | **失败**；[崩溃后界面](35-clear-result.png)，层级 34–36，日志末尾 SwiftData fatal error。 |

独立 Action 的类型归属来自源码：通知使用 `CalendarNoticeAction`，导航选择使用 `CalendarDebugNavigationAction`，清空确认使用 `ClearDownloadedDataAction`。表中按钮、页面、Tab、页数和 ID 变化均来自实际点击证据。此记录没有把源码或自动测试结论当成设备证据。

ACT-06 中的两类 Action、串行队列和模态离开确认路径已取得实际交互证据。ACT-03 的清空完成结果未通过，不能将全部交互验收标记为完成；修复后须复验清空路径。

## 清空崩溃

复现前提为 App 已加载完整日期数据，并显示过日历首页。随后切到设置清空。06:55:12 的实际日志依次为：

1. `Clearing downloaded seed store and restoring bundled base store`。
2. SQLite：`database integrity compromised by API violation: vnode unlinked while in use`，以及 `invalidated open fd`。
3. 结果提示 `presentAlert outcome=queued`、`resumePresentation outcome=applied`。
4. `SwiftData/BackingData.swift:897: Fatal error: This model instance was destroyed by calling ModelContext.reset and is no longer usable`，涉及 `ChineseLunarMonth/p29584`。
5. 标准输出连接关闭；工具状态 `Crashed`，屏幕为 SpringBoard。

日志显示清空操作及结果提示入队已经执行；不能据此声称结果通知成功展示。旧模型引用为何在 store 替换后继续访问，仍需源码定位；本验证未判断该问题由本次 Action 改造引入还是原有生命周期问题。

## 其他观察与边界

- 设置“调试操作”的外层行 hitPoint（220, 598.5）第一次未打开菜单；使用同次最新层级中内部 label hitPoint（102, 598.5）后打开。记录为非阻断可点击范围观察，不据此认定本次改动回归。
- 日志出现 `Update NavigationRequestObserver tried to update multiple times per frame`；对应 Tab 切换仍成功完成。没有从该日志推导额外功能失败。
- 这轮没有可见的提示文案重叠、截断或按钮不可读。长调试页通过滚动访问，未把正常滚动遮挡当作布局错误。
- 未验证真机、清空失败结果提示、下载失败提示，以及完整日期数据重新下载。清空崩溃后停止设备交互并交回主 agent，保留 session 未关闭。

原始结论可核查于 [层级摘录](interaction-hierarchy-excerpts.txt) 和 [日志摘录](interaction-log-excerpts.txt)。日志摘录将 Simulator AppGroup 绝对路径及临时呈现身份替换为占位符，完整本地日志仍保留。
