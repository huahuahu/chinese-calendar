# Issue #164：安全替换 Store 的 Simulator 复验

- 日期：2026-10-23，实际交互 07:09–07:17（+0800）。
- 代码：`c851e37260508ee22dfcaeb8995be4c140b4824f`。开始时为 `5fc6a104` 加同一份未提交修复；交互期间主 agent 只提交源码，未改变产品文件。
- 源码快照：排序后的 `Apps/`、`Sources/` 全部 326 个 Swift 文件（排除 `.build`），逐个拼接路径、NUL、内容、NUL，SHA-256 为 `1e178855c4269de3bbe28acad76c1c37ca5135b6f41eceefbef931263b3b72c9`。交互前后相同；修复涉及的 11 个文件也全部匹配本轮 review 快照。见 [开始快照](source-before.json)、[结束快照](source-after.json)。
- 环境：`ChineseCalendar-iOS`，iOS 27.0，`chinesedate iPhone 18 Pro Max (885f)`，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，竖屏 440 × 956 pt。
- 工具：原生 Xcode MCP；先读取共享 sessionDefaults，并用 XcodeOpenWorkspace 确认项目、scheme 和目的设备。沿用主 agent 已安装启动的 session `Verify Safe Store Replacement`，workspace `workspace-edAhOBzbKD`。
- 进程：44 次截图/层级捕获全部为 `Running`，App PID 始终为 `68489`；最终 console launch session `79b9761680` 状态 `started`。
- 方法：按最新层级 hitPoint 点击，逐次检查截图和层级；Alert 切换动画结束后重新捕获稳定截图。只通过正常 UI 下载及清空数据，没有注入业务状态、改写 seed 文件、重装 App、修改产品源码或提交代码。
- 完整 44 次捕获、命令、工具状态和日志位于本地忽略目录 `.output/issue-164-store-device/`，索引为 `manifest.json`。此处仅保留六张图、精简层级、日志与哈希。

## 核心结果

| 场景 | 实际步骤和结果 | 证据 |
| --- | --- | --- |
| 基础数据正常下载，真实加载月格 | 首页“下载”启动完整数据下载。日志记录传输 207097856 bytes、校验及安装；随后实际显示“丙午年 九月大”、2026/10/10–2026/11/8 和日期格，包含初一与今天十四。 | 01–06；[完整日历](05-full-calendar.png)。 |
| 完整数据清空取消 | 已浏览月格后进入设置，显示“已安装完整日期数据”；打开清空确认，点“取消”，设置仍显示完整数据。 | 06–08。 |
| 完整数据确认清空，结果通知可操作 | 再次打开确认，点红色“清空已下载数据”。稳定画面出现“已清空”及“已删除下载数据，并恢复到内置基础日历数据”；点“好”后回设置，显示“正在使用内置基础数据”。App 保持同一 PID。 | 09–12；[成功通知](11-clear-success-stable.png)。 |
| 清空后继续导航 | 切日历显示“需要完整日期数据”与下载入口；切朝代正常显示秦、西汉等列表；切回设置正常。 | 13–15；[基础数据日历](13-base-calendar.png)。 |
| 基础数据重复清空 | 在基础数据状态再次确认清空，仍出现可确认的“已清空”；点“好”后设置正常。这里验证重复清空的可观察行为，container 身份和 artifact 身份属于自动测试/源码证据。 | 16–19。 |
| Sheet 业务提示串行 | 从设置调试操作进入“导航测试 → Sheet 打开主标签页”，在 Sheet 内选择“连续显示两个 Alert”；先显示业务提示 1，点“好”后显示业务提示 2，再点“好”回同一个设置 Sheet。每次层级只有当前一个 Alert。 | 21–31；日志同一模态层 `presentAlert applied → queued → resumePresentation applied`。 |
| Sheet 下载状态中确认清空 | 第二次通过正常 UI 启动下载后打开上述 Sheet。07:16:28 的设置为“完整数据下载中”、进度 88%；打开确认时背景显示 92%；07:16:46 点确认后为“正在清空”（禁用），进度 95%，07:16:54 仍在等待。07:17:02 日志记录清空，07:17:08 实际出现成功通知，点“好”后仍留 Sheet 的设置页面并显示基础数据。 | 37–42；[清空前状态](37-modal-before-clear.png)、[模态成功通知](41-modal-clear-success.png)。 |
| 模态清空后导航和关闭 | 在同一 Sheet 切日历，出现基础数据空态和下载入口；点击左上“关闭”，回到 root 设置，仍显示基础数据。 | 43–44；[模态基础日历](43-modal-base-calendar.png)。 |

原先“加载完整月格 → 设置确认清空”的崩溃路径在本修复上通过，且成功结果 Alert 已实际显示并操作。模态清空前后日志使用相同的模态身份（摘录中标为 `<modal-A>`）；成功 Alert、Tab 切换、Sheet 关闭都有实际交互证据。

## 日志核查

最终通过原生 GetConsoleOutput 查询 `vnode unlinked|invalidated open fd|ModelContext.reset|Fatal error`，返回 `totalCount: 0` 且未截断；最终捕获的完整 App 日志也没有这些模式。这一结论限定于本次 launch session。

三次清空分别在 07:11:11、07:12:00、07:17:02 记录 `Clearing downloaded seed store and restoring bundled base store`，随后结果提示 `queued → resumePresentation applied`。这些日志与成功通知截图对应，未将仅入队当作成功展示。

层级及命令见 [交互摘录](hierarchy-excerpts.txt)，运行日志、旧崩溃模式查询和其他告警见 [日志摘录](log-excerpts.txt)。[上一轮失败证据](../README.md) 保持原样。

## 其他观察与边界

- 第二次下载的传输/安装日志在 07:12:27 已结束，但 UI 直到 07:16 仍逐步显示下载进度；清空确认后的“正在清空”约持续 16 秒才有成功事件。这里按实际 UI 状态记录为“下载状态中清空”，没有把较早的安装日志当作页面已完成切换，也不能据此声称验证了仍在传输中的 URLSession 取消。第二次完整月格未观察到。
- 完成串行提示后重新打开调试菜单，“导航测试”的 hitPoint 在 33–35 两次点击（中间重新捕获）均未展开子菜单；随后点菜单外可关闭，Tab 和清空仍可用。保留为调试菜单可点击性观察，未确认与本次 Store 修复的因果关系；因此未再复跑“离开当前页面”确认路径。
- 日志仍有 `onChange(of: Optional<FullStoreDownloadProgress>) action tried to update multiple times per frame` 和 `Update NavigationRequestObserver tried to update multiple times per frame`。已保留摘录，不把它们解释为本次清空崩溃重现。
- 本轮没有看到文案重叠、不可读、异常截断或清空后导航错乱。月格底部和横向月份项的正常滚动裁切不作为布局故障。
- 未验证真机、进程重启后的恢复、清空失败提示、下载失败提示、磁盘/网络故障注入，也没有把 469 次自动测试执行或源码审查替代这些设备证据。
- session 按主 agent 要求保持开放并交回，最终停在 root 设置页。
