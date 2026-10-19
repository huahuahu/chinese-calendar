# Issue #148 Simulator 交互记录

- 时间：2026-10-19；设备 `16A9CAA7-45CE-46D5-8915-F61531FC617C`，`chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0。
- 工具：原生 Xcode MCP `DeviceInteractionSynthesize`；每步按当前 hierarchy hitPoint 操作并复读结果，动画截图未稳定时另行采集。
- 首轮版本：主代理在交互开始前通过 `DeviceInteractionInstallAndRun` 安装的 Issue #148 工作区版本，基于 HEAD `63eb6797ad58cf7767a93000ef4786a11c788da2`，含未提交导航宿主实现。**首轮不含随后把 `NavigationScopeView` builder 分支从 `presentation.isPresented` 改为 `presentation.id != .root` 的调整**，不能将首轮证据等同于最终 `source-manifest.json`。
- 保留原有完整日期数据；没有点击真实下载或清空数据。选年后用“今天”恢复初始日期。

## 首轮实际结果

| 场景 | 交互结果 | 关键证据 |
| --- | --- | --- |
| 根历史值导航 | 从“朝代”列表点击“秦”后进入秦详情，返回按钮为“朝代” | `01-history-link.txt/png` |
| 设置栈 push / pop | 调试菜单 Push 打开页数 1，再 Push 到 2，返回恢复 1。第一页 ID `271EC436-9BDD-438D-9B47-22D0B9547187`，第二页 ID `C9C2B3FC-338B-40D9-AC8E-450C5A975096` | `02-settings-push-1.txt/png`、`03-settings-push-2.txt` |
| 根 Tab 路径保持 | 设置第二页切到朝代仍为秦详情；切回设置仍是页数 2 和原第二页 ID。后续从朝代切回设置仍保留第一页 ID | `04-tab-state-retained.txt` |
| sheet 内栈 | 设置第一页打开 sheet，作用域为模态、页数 0；Push 到 1，再返回 0 与原 sheet ID `5382A1BE-57B8-4EDB-82ED-D813628980E3` | `05-sheet-root.txt/png`、`06-sheet-push-1.txt` |
| 嵌套 full-screen | 从上述 sheet 打开 full-screen，新的模态页数为 0，ID `026242F3-3DE6-4244-8121-D3D2ADA06A58`；关闭子层回到原 sheet ID。可见页面均为单个 NavigationBar | `07-sheet-fullscreen-child.txt/png`、`08-child-dismiss-parent-retained.txt` |
| 两条业务 Alert | 在 sheet 点击“连续显示两个 Alert”；先显示“业务提示 1”，点“好”后显示“业务提示 2”，再次点“好”回到 sheet | `09-queued-alert-first.txt/png`、`10-queued-alert-second.txt/png` |
| Alert 与外部导航协调 | 点击“Alert 期间请求跳转历史”先显示业务提示 1；点“好”才出现“离开当前页面？”。第一次选择“留在当前页面”回到原 sheet；第二次重复流程并选择“关闭并前往”，sheet 关闭后进入朝代栈导航测试，页数 2，返回目标秦 | `11-alert-before-external-navigation.txt/png` 至 `14-confirm-navigates-history.txt/png` |
| 根日历选年回传、重开 | 日历 2026 打开年份选择器，选 2027 后回到丁未年正月，日期为 2027/2/6–2027/3/7；再次打开选择器正确选中 2027；可再选 2026 返回日历 | `15-year-result-2027.txt/png`、`16-year-picker-reopen-2027.txt` |
| 下载演示多 Tab 容器 | “下载进度布局预览”全屏打开；“进度场景”及“切换检查”各只有一个 NavigationBar。切换 Tab 保留“第 1/5 步·准备下载”附件 | `17-download-preview-first-tab.txt/png`、`18-download-preview-second-tab.txt/png` |
| 下载演示子详情与容器重开 | 第二 Tab 点击进度附件打开“完整数据下载”子 sheet，关闭回到第二 Tab；切回第一 Tab，点击“完成”返回设置；再次从菜单打开，正常显示新容器；最终再次关闭回设置，仍显示已安装完整日期数据 | `19-download-child-detail.txt/png`、`20-download-preview-reopen.txt` |

## 首轮边界与后续补验

- 未观察到与本次实现相关的功能或布局异常；没有应用退出，采集状态均为 `Running`。
- 原生 session 全程有效，没有发生 `Session not found`；截图偶尔捕获在动画中，已对关键 Alert / sheet 截图重采，不据此记为 UI 缺陷。
- 下载演示两个 Tab 正式界面没有局部 push 控件或导航调试菜单。因此首轮只验证多 Tab 容器和子模态；两个栈的 push destination 注册与独立性已在第二轮用临时入口补验，见下文。
- 首轮只从根日历实测选年；第二个独立日历发起页的回调隔离已在第三轮正式版本补验。
- 首轮没有单独实测全屏内 push/pop，第二轮已补验。sheet 内再次嵌套 sheet、业务 Alert 按钮自带跳转不在三轮实际覆盖中；已测的嵌套组合包括 sheet → full-screen、full-screen 多 Tab → sheet/full-screen。
- 最终源码恢复并重装后的 sheet push → 关闭 → 重开已在第三轮补验，确认后续 builder 判断调整。
- 首轮 session key `Issue 148 Runtime` 已调用 `DeviceInteractionEndSession`，返回 `Session stopped`；Simulator 已释放供主代理测试及 Preview。

## 第二轮：临时多 Tab 入口补验

- Session：`Issue 148 Modal Tabs`。主代理重新安装的版本已包含稳定的 `presentation.id != .root` 判断及历史页 Preview 的显式 `ForEach` closure。
- 版本额外差异：[modal-tabs-harness.patch](../modal-tabs-harness.patch)。仅在下载演示两个 Tab 的根 Form 添加 `CalendarDebugNavigationActions()`，没有新增 navigation host、destination builder 或栈。此轮能证明现有两个模态栈的运行时路由注册，但临时入口本身不是最终生产界面。
- 用 A 表示“进度场景”，B 表示“切换检查”。

| 场景 | 交互结果 | 关键证据 |
| --- | --- | --- |
| A 独立 push | A 从根 push 到 1，ID `48E56949-E127-4E27-B22F-8A91F319FCC6`，再 push 到 2，ID `12F43011-BDAE-430F-95C2-92C2C9E886EE`，均为模态作用域 | `21-modal-tab-a-push-1.txt`、`22-modal-tab-a-push-2.txt/png` |
| B 根与独立路径 | A 为 2 时切 B，仍是“切换检查”根，Pop 禁用；B push 到 1，ID `F2B2FE30-6ADE-4405-AA90-CB2471ABAE6C` | `23-modal-tab-b-empty-root.txt`、`24-modal-tab-b-push-1.txt/png` |
| 切换与 pop 隔离 | 切回 A 仍为页数 2 与原 ID；A pop 到 1 后恢复 A 的第一页 ID；切 B 仍为原页数 1 与原 B ID | `25-modal-tab-a-retains-2.txt` 至 `27-modal-tab-b-unaffected-by-a-pop.txt` |
| full-screen 子层 push/pop | 从 B 打开 full-screen 子层，根页数 0、ID `2CA9E0D9-2748-42DE-9E36-DC49A695A6AD`；push 后页数 1、ID `E785F4A9-8862-4ADC-A5EA-63CFB7A80C29`；返回恢复子层根 ID 与页数 0；关闭回到原 B ID、页数 1 | `28-modal-tab-b-fullscreen-child.txt` 至 `31-fullscreen-dismiss-restores-tab-b.txt/png` |
| sheet 子层与再次切换 | B 打开 sheet，独立页数 0；关闭回 B 的原 ID、页数 1；再切 A 仍为 A 第一页 ID、页数 1 | `32-modal-tab-b-sheet-child.txt` 至 `34-modal-tab-a-still-retained.txt` |

- 第二轮未观察到重复导航栏、空白目的页、路径串扰、模态关闭丢失父页或应用退出。以上子层与 Tab 变化都通过新 hierarchy 和截图核实。
- 最后关闭整个下载演示容器回到设置，仍显示“已安装完整日期数据”。没有下载或清空数据。
- 第二轮结束时停止设备交互并释放 Simulator，按主代理要求暂时保留 `Issue 148 Modal Tabs` session；后续由主代理测试过程使该会话失效。第三轮改用新会话并完成最终源码补验，见下文。

## 第三轮：最终正式版本

- Session：`Issue 148 Final`；主代理在开始前重新 `InstallAndRun`。本轮开始时再次核对项目、scheme、Simulator 和源码摘要。
- 代码快照：[source-manifest.json](../source-manifest.json)，SHA256 `24707a8ea6ad65daf5263308ac829885f79247c53ec3c7c721982a394b002bdf`。
- `FullStoreDownloadPreview.swift` SHA256 `8619028b36f3d67c401fb60113427617cfb47763a9104a4f05ac8b065cbdf519`，与移除临时入口后的摘要一致。本轮没有修改源码。

| 场景 | 交互结果 | 关键证据 |
| --- | --- | --- |
| sheet push 后直接关闭 | 设置父页为页数 1、ID `820673EC-EC5D-435D-BBF9-C2EC7CD6DE7B`；sheet 根为页数 0、ID `B4E1F7CA-FC70-4736-B955-F7CEB8C79C15`；sheet push 到 1 后点击关闭，返回父页的页数与 ID 完全不变 | `35-final-parent-settings-push-1.txt` 至 `38-final-sheet-dismiss-parent-unchanged.txt` |
| sheet 重开 | 再次打开 sheet 为新 ID `83DF7388-08FB-45D0-B352-26C5C9B082AD`，页数 0、Pop 禁用；关闭后父页仍为原页数 1 与原 ID | `39-final-sheet-reopen-empty-path.txt/png` |
| 两个日历发起页的选年隔离 | 根日历选 2027，显示丁未年正月。进入设置调试页触发“模拟打开今年的 Deep Link”，来到带返回按钮的独立 2026 日历页；在此页选 2028 后显示戊申年正月，日期 2028/1/26–2028/2/24；pop 回根仍显示 2027 丁未年正月、日期 2027/2/6–2027/3/7，根没有返回按钮。随后点击“今天”恢复初始当前日期 | `40-final-root-calendar-2027.txt/png` 至 `43-final-pop-root-still-2027.txt/png` |
| 正式下载演示移除临时入口 | 第一 Tab 顶部恢复“字号”和“固定下载阶段”，没有导航动作；第二 Tab 恢复说明文字，没有临时 Form 或导航动作。两个 Tab 各只有一个 NavigationBar；切回第一 Tab 点“完成”正常关闭，设置仍显示已安装完整日期数据 | `44-final-download-tab-a-no-harness.txt/png`、`45-final-download-tab-b-no-harness.txt/png`、`46-final-data-preserved.txt` |
| 最终朝代 NavigationLink | 实际进入朝代根列表，再点击秦，进入秦详情且返回目标为朝代；证明最终显式 `ForEach` closure 版本的列表值导航仍可运行 | `47-final-history-root.txt`、`48-final-history-link-qin.txt/png` |

本轮四项均通过；没有观察到空白目的页、重复导航栏、页状态串扰、关闭重开异常或应用退出。全程未触发真实下载、清空数据或源码修改。最终停留在秦详情。

`Issue 148 Final` 已调用 `DeviceInteractionEndSession`，工具返回 `Session stopped`；Simulator 已释放。本报告的三轮交互、主代理的自动测试与 Preview 是不同证据类型，不相互替代。
