# 不修改 NavigationCore 的业务适配复验

- 时间：2026-10-07 13:19–13:22（Asia/Shanghai）。
- 版本：本目录 `source-sha256.txt`，业务导航适配版本；运行前主 Agent 已安装不带harness的最终代码。交还设备后校验清单时，206项中205项一致，仅 `ChineseCalendarStoreCoordinator.swift` 已被主 Agent 加入下一轮临时harness而不同；本轮运行的已安装二进制在交还之前未重建。
- Session：`Issue 145 Business Adapter`；workspace `workspace-deC0lVsFJy`；scheme `ChineseCalendar-iOS`；Simulator UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，原iPhone 18 Pro Max/iOS27.0，竖屏。
- 原生 DeviceInteractionSynthesize，点击/滑动均基于最新hierarchy。deep link仅使用指定Simulator的simctl openurl（已确认两套MCP无URL opener）。未修改源码、配置、数据文件；现有完整库保留。

## 本轮实际通过

| 路径 | 观察 | 证据 |
| --- | --- | --- |
| picker选年、关闭、重开 | 2026选2025回原页，重开居中高亮2025；按钮关闭和下滑取消均回原页，各自之后再打开成功，没有根关闭状态卡住 | `01`–`08`，`08-picker-stable.png` |
| picker连续hot deep link | 可见时依次2020、2021；最终2021。日志13:20:36.370511首次Deferred，13:20:36.538923第二次仍Deferred，13:20:36.959369 Applied。证明两请求都发生在关闭等待期间 | `09-link-dispatch.json`、`10-link-last-wins.png/.txt`、`runtime-console.log` |
| demo fullScreen→子sheet | 选择50%后打开详情，详情50%；关闭子sheet仍回原演示50%，再开成功 | `11`–`16`，`16-child-stable.png` |
| 子sheet热deep link | 子详情可见时year/2024，整棵fullScreen+sheet树消失，进入2024日历，无残留蒙层 | `17-child-hot-link.png/.txt` |
| 真实coordinator模拟详情 | 实测2%→28%→校验/完成，完成态稳定可见，随后自动关闭回设置、附件消失 | `18`–`24`，`23-simulation-completed.png/.txt` |
| 自动关闭后宿主复用 | 切日历仍2024；再次打开picker成功，2024居中选中，再关闭正常 | `25`–`28`，`27-picker-host-reused.png` |

## 边界

- 全程App Running，实际查看的页面未见重复导航栏、重叠文字、持久空白或残留模态。
- 设置在操作前后均显示「已安装完整日期数据」；本轮模拟下载不替换数据库，也不代表容器切换或真实网络安装证据。
- 本轮仅覆盖NavigationCore撤回后受影响关键路径，不重跑历史、BCE或其它设备矩阵；早先报告属于其各自二进制，不能混同本轮快照。
- 当前停在2024日历destination，操作权已交还主 Agent，session保持开放供受控内存容器替换专项。

## 正式代码恢复后最终冒烟（13:28）

主 Agent 已移除harness，以仅继承scheme参数的原生InstallAndRun启动正式代码。本 Agent独立核对本目录source-sha256清单，206/206个Swift文件一致。

- 设置仍显示「已安装完整日期数据」，截图和层级为 `47-final-installed-data.png/.txt`。
- 首页恢复真实2026八月；picker恢复完整连续年份列表，2026居中勾选。按钮关闭、重开、再次关闭全部正常。`48-final-full-picker.png/.txt`。
- 最后停在正式首页2026八月，App Running，没有验证模态、下载附件或残留蒙层。`49-final-calendar.txt`。
- 本 Agent已交还设备权，session未自行结束，由主 Agent统一结束。正式恢复后的此轮仅短冒烟，没有重复全矩阵。
