# 合并前深链接定向验证

- 日期：2026-10-22，19:26–19:40（Asia/Shanghai）。
- 关联：[实现与验收结果](001-result.md)。
- 源码：与结果记录中的最终 22 文件指纹 `9d63e91b24777701928d92d42f20b649731122f860b23f18495552de026c680a` 一致；本次只验证，没有修改产品代码。
- 环境：`chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27，竖屏；原生 Xcode MCP 交互。两 MCP 没有 openURL 操作，URL 通过本地 `xcrun simctl openurl` 送入。

## 系统返回后重开相同链接

审查提出一个待验证假设：系统返回若只改变紧凑栏、不改变根值，再应用同根可能不会重新打开目标。实际结果如下：

| 操作 | 稳定结果 |
| --- | --- |
| 西汉资料入口 → 系统 Back | 返回[朝代时间线](evidence/premerge-same-link-back-timeline.png)。 |
| 再发送完全相同的 `chinesecalendar://dynasty/orthodox_sequence_qin_han_to_prc_western_han` | 重新进入[西汉资料入口](evidence/premerge-same-dynasty-link-reopened.png)，帝王 13、年号 43。通过。 |
| 王莽详情 → 系统 Back 到新朝资料入口 → 再发送 `chinesecalendar://emperor/xin_emperor_0000` | 直接重新进入[王莽详情](evidence/premerge-same-emperor-link-reopened.png)，返回标签为新。通过。 |

此轮沿用安装包，主程序与 debug dylib 的 SHA-256 均与 e708 项目的 DerivedData 构建产物一致；AX PID 始终为 `77944`。非 workspace 会话返回 `NotRun`，但 AX、截图与按钮／URL 操作均证明应用在运行；没有据此误判崩溃。这里验证最终可见行为，不推断 SwiftUI 内部 Binding 写回顺序。

## 首次跨 Tab 的额外观察与复验

上述定向操作之前，应用最初显示日历。首次发送西汉 URL 后，即时 AX 显示资料入口而截图仍是日历；随后无 Back 操作的捕获显示朝代时间线。该现象只观察到一次，初轮没有重现相同初始条件，因此单独保留，不混入已经通过的返回后重开场景。

随后使用原生 `DeviceInteractionInstallAndRun(commandLineArguments: [])` 重新构建当前源码并启动，连续两轮都先确认日历稳定、未访问历史，再仅发送一次相同西汉 URL：

- 第一轮 PID `94224`，状态 `Running`，19:38:55 稳定显示[西汉资料入口](evidence/premerge-first-link-trial-1.png)。
- 第二轮重新启动为 PID `96749`，状态 `Running`，19:40:55 同样稳定显示[西汉资料入口](evidence/premerge-first-link-trial-2.png)。

两轮均没有再次发送链接、点击历史或按返回来促成目标页面；没有崩溃、意外退出或新的文字重叠／裁切。此前一次异常未复现，未能确认为当前可重复的缺陷；这两次成功也不证明所有时序变体都已排除。

两轮日志都出现 `Update NavigationRequestObserver tried to update multiple times per frame.`，最终页面均正确。本次未测量其内部原因，不将警告等同于已证实的导航故障，也不把日志描述为无警告。

## 交付基线与范围

本地构建、402 项测试与交互证据最初基于 `10298146`。准备提交时远端 main 新增 `b347895e`（PR #162），只移动 43 个 NavigationCore Swift 文件（全部 `R100`，内容未变）并更新该模块 README。工作分支已无冲突 fast-forward 到新基线，历史功能的源码指纹不变；最终组合的构建与测试交由 PR CI 确认。

这些定向检查仅覆盖上述 iPhone 路径；不扩展为真机、VoiceOver、Dynamic Type、任意窗口缩放或完整操作系统冷唤起验证。交互均已停止，结束会话工具确认无存续会话。详细专项报告和临时 AX／日志保存在被忽略的本地审查目录，以上关键结果与截图随任务交付。
