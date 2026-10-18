# Issue #145 定位修复与受控容器切换复验

- 时间：2026-10-07 11:12–11:15（Asia/Shanghai）。
- 工具与设备：原生 Xcode DeviceInteractionSynthesize；session `Issue 145 Store Verification`；workspace `workspace-deC0lVsFJy`；scheme `ChineseCalendar-iOS`；Simulator `16A9CAA7-45CE-46D5-8915-F61531FC617C`（iPhone 18 Pro Max，iOS 27.0），竖屏。
- 二进制：主 Agent 安装了导航最终实现（包含 picker section/row ID 修复和重复打开 guard）加临时 DEBUG harness；启动参数 `--issue-145-memory-switch`。harness diff/hash 见 `temporary-store-switch-harness.diff`、`temporary-store-harness-sha256.txt`。
- 第二条场景前由本 Agent 使用原生 `DeviceInteractionInstallAndRun` 以 `["$(inherited)", "--issue-145-memory-switch"]` 重启，恢复磁盘完整库；未修改源码或数据文件。

## 定位与重复触发

1. hot link `chinesecalendar://year/-1` 进入公元前2年，双击该页年份入口，仅出现一层 picker。公元前2年在列表中部，勾选与 AX Selected 正确。`20-bce-picker-fixed.png/.txt`。
2. picker选择公元1年，返回原destination而无残留sheet；再次打开，公元1年居中勾选。`21-ce-picker-fixed.txt`。
3. 第二条容器场景中，完整库2026 picker仍居中勾选，证明现代年份定位保留。`26-switch-old-picker.txt`。

## 受控场景 1：下载详情穿越容器替换

- 设置启动真实 coordinator 的模拟下载，打开详情；采样到80%、92%、校验、完成。
- harness 在 `.completed` 后构造 `isStoredInMemoryOnly` 的 PreviewSampleData container，并赋新 identity；日志 marker：`11:13:34.304930 Issue145 controlled in-memory container switch completed`。证据 `22-switch-console.log`。
- `11:13:35.452` 捕获的画面仍显示「完整数据下载」及五阶段完成，证明容器替换后详情宿主继续存在。`22-switch-complete-detail.png/.txt`。此前一个捕获的截图比 hierarchy 稍早，已改用后续稳定帧保存，避免把安装态图误标为完成态。
- 后续捕获回到设置且下载附件消失，详情自动关闭。`23-switch-auto-dismiss.txt`。未精确测量两秒时长；实际关闭顺序与原延迟清理相符。
- 切日历，2026显示样例的正月与三个已填充月份；打开picker只有8个样例年记录（BCE221、BCE220、BCE2、BCE1、CE1、2025、2026、2027），不再是完整连续年份列表。`24-switch-sample-picker.png/.txt`。
- picker可见时hot link year/2025，正常关闭并进入样例2025十一月。`25-switch-hot-link.txt`。

## 受控场景 2：撤销依赖旧容器的 picker

- 重启App，首页恢复真实完整库的2026八月（2026/9/11–10/9），设置显示已安装完整日期数据。
- 启动模拟下载，立即切日历并打开picker；2026居中勾选，周围显示连续完整年份。`26-switch-old-picker.txt`。
- 容器替换 marker：`11:15:18.469647 Issue145 controlled in-memory container switch completed`。`27-switch-picker-console.log`。
- 旧picker关闭；过渡中曾捕获正在下落的空sheet，随后重新捕获确认完全消失，稳定画面为样例2026正月。`27-switch-old-picker-dismissed.png/.txt`。没有把呈现动画中间帧判为持久空白缺陷。
- 重开picker仅有上述样例年份，2026勾选；选2025后回原页并显示样例十二月（2025/12/9–2026/1/7）。`28-switch-new-picker.txt`、`29-switch-new-selection.txt`。

## 证据边界

- 两条场景验证的是生产 root/.id/presentation host/onChange 链路承受**受控内存容器和identity替换**的行为，不是真实网络下载、文件安装或SQLite替换。
- 全程没有清空、覆盖或重装已下载的真实完整数据库。原数据能在重启后恢复已观察到。
- 这轮二进制带临时验证harness，不能当作移除harness后的最终安装证明；最终产品代码的安装与冒烟由主 Agent 收尾。
- 未发现新崩溃、重复模态或持久空白层。当前App停在内存样例2025十二月；session保持开放，Xcode/Simulator操作权已交还主 Agent。

## 正式代码恢复后的最终冒烟（11:16–11:17）

主 Agent 已移除临时harness，以仅继承scheme参数重新原生安装运行；本 Agent 复核 `final-source-sha256.txt`，205个Swift文件哈希全部一致。

- 设置明确显示「已安装完整日期数据」。`30-final-full-data-installed.png/.txt`。
- 首页为真实2026八月，picker为完整连续年份列表，2026居中勾选。按钮关闭回原首页，重开仍为2026且没有残留模态。`31-final-picker-reopen.png/.txt`。
- 再次关闭后停在正式首页，无下载附件或验证模态，App Running。`32-final-calendar.txt`。
- 已交还全部设备交互权，由主 Agent 关闭session。此轮只做恢复后的短冒烟，不重复声称运行完整矩阵。
