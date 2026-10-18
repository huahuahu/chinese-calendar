# 无 NavigationCore 修改版本的受控容器替换验证

- 时间：2026-10-07 13:25–13:27（Asia/Shanghai）。
- 运行上下文：原生 Xcode `DeviceInteractionSynthesize`；session `Issue 145 Business Adapter`；workspace `workspace-deC0lVsFJy`；scheme `ChineseCalendar-iOS`；Simulator UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iPhone 18 Pro Max/iOS27.0，竖屏。
- 代码：`source-sha256.txt` 业务适配版本 + 本目录 `temporary-store-switch-harness.diff`、`temporary-store-harness-sha256.txt` 所记录的临时验证改动。NavigationCore保持撤回后的原样。
- 参数：`["$(inherited)", "--issue-145-memory-switch"]`。主 Agent安装首轮；第二条前本 Agent原生 `DeviceInteractionInstallAndRun` 使用相同参数重启。
- 所有点击均来自最新hierarchy hitPoint。没有修改源码、配置、数据文件，没有清除完整库。所有采样为Running，无崩溃。

## 场景1：详情跨容器切换保持与自动关闭

1. 设置显示完整日期数据已安装，启动真实coordinator的模拟下载并打开详情。
2. 捕获92%后继续采样到完成；`13:26:04.817728`出现marker `Issue145 controlled in-memory container switch completed`，证明新in-memory container和新identity已写入真实coordinator.state。`35-switch-console.log`。
3. marker后的稳定截图仍显示「完整数据下载」及五阶段完成；之后自动关闭到设置、附件消失。`34-switch-completed.png/.txt`、`35-switch-auto-dismiss.txt`。未精确计时两秒。
4. 切日历显示样例2026正月；picker只有8个样例年（BCE221、BCE220、BCE2、BCE1、CE1、2025、2026、2027），2026被选中。`36`–`38`，`38-switch-sample-stable.png`。

## 场景2：旧picker失效、重开使用新context

1. 原生重新安装运行后恢复真实完整库首页2026八月，设置再次显示完整日期数据已安装。`39-restart-full-data.txt`。
2. 启动模拟，立即切日历并打开旧picker；显示完整连续年份列表且2026居中勾选。`40`–`42`。
3. `13:27:16.570305`出现同一切换marker；旧picker自动关闭，稳定页面为样例2026正月，无残留空白层。`43`–`44`、`44-picker-switch-console.log`、`44-picker-dismissal-settled.png`。
4. 重开picker仅8个样例年份，选2025返回原页显示样例2025十二月（2025/12/9–2026/1/7）。`45-picker-new-context.txt`、`46-picker-new-selection.txt`。

## 结论与边界

两条均通过。业务层的根host/节点关闭、store identity变更与新ModelContext读取链路在受控替换下运行正常。

这证明的是**受控内存容器/identity替换**，不是网络下载、文件安装或真实SQLite替换。磁盘完整库未改动，第二条前重启恢复已实际观察。临时harness尚在本轮二进制中；主 Agent将移除并安装正式代码，该恢复安装须单独记录，不能由本报告代替。

当前App停在样例2025十二月，session未结束；操作权已明确交还主 Agent。本 Agent不再操作设备或恢复源码，避免冲突。

## 正式代码恢复后最终冒烟（13:28）

主 Agent 已移除harness，以仅继承scheme参数的原生InstallAndRun启动正式代码。本 Agent独立核对本目录source-sha256清单，206/206个Swift文件一致。

- 设置仍显示「已安装完整日期数据」，截图和层级为 `47-final-installed-data.png/.txt`。
- 首页恢复真实2026八月；picker恢复完整连续年份列表，2026居中勾选。按钮关闭、重开、再次关闭全部正常。`48-final-full-picker.png/.txt`。
- 最后停在正式首页2026八月，App Running，没有验证模态、下载附件或残留蒙层。`49-final-calendar.txt`。
- 本 Agent已交还设备权，session未自行结束，由主 Agent统一结束。正式恢复后的此轮仅短冒烟，没有重复全矩阵。
