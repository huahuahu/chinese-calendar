# Debug Actions 增量设备验证

日期：2026-10-11。项目：d18d worktree 的 `ChineseCalendar.xcodeproj`；scheme：`ChineseCalendar-iOS`。设备为 `chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。

本轮只验证新增的设置调试入口与导航测试动作，不沿用上一轮 scoped-router 的交互通过结论。

## 已确认

- 读取 `.xcodebuildmcp/config.yaml` 并原生打开项目，工作区 `workspace-RrA5WV2tRC` 返回的 scheme 与设备匹配共享配置。
- 在最终源码收紧通知之后，原生 `DeviceInteractionInstallAndRun` 返回 `Application installed and running`。
- 实际设置页的调试分区只有新的“调试操作”入口；说明显示“下载调试只模拟进度，不访问网络、写入文件或替换日历数据库。”，旧两个下载按钮不再直接平铺。见 `01-settings.png` 和 `01-settings.txt`。
- 同一截图与 hierarchy 显示“已安装完整日期数据”。本轮没有清空数据，没有发起真实下载。
- 点击实际 Menu 内层控件后，一级菜单 hierarchy 包含“导航测试”和“下载调试”。见 `02-debug-menu.txt`。尚未得到稳定的导航子菜单或测试页结果。

## 未完成的交互

- 导航子菜单 Push / Sheet / 全屏入口。
- 设置 Push 测试页 → 再次 Push → Pop，以及作用域、path 页数和 UUID 的变化。
- 测试页 Sheet → 子全屏 → 关闭回父，保留父页面 ID/path。
- 模拟今年 DeepLink 的取消保留、批准关闭整个模态层级。
- 跨历史 Tab Push 及已有 modal 时的确认。
- 下载子菜单的预览入口、模拟进度与详情。
- Release 下入口不可见的运行时检查；Release 编译由主 Agent 单独记录。

## 工具受阻与证据边界

原生创建的 `Debug Actions Runtime QA` 和 `Debug Actions Verification` 均在若干调用后报告 `Session not found`。点击导航菜单附近出现过 SpringBoard / App 回默认日历的画面变化，但没有取得可归因于 App 的异常日志或崩溃报告，因此未认定产品崩溃。

备用 XcodeBuildMCP 的 active defaults 已核对为同一项目、scheme 与 UUID，未修改 defaults。它能截图，但 `snapshot_ui` 持续返回相同 screenHash `0nnoq93`；刷新 snapshot 后立即调用 `tap` 返回成功，后续快照仍不变。单独跨调用操作还出现 `SNAPSHOT_EXPIRED`，不能把这些动作返回值当作页面通过证据。

CUA 后续定位到 Device Hub 中同名目标设备，能读取真实年份选择器并用 AX 操作关闭；之后坐标操作返回 `noWindowsAvailable`，最终一次截图/点击尝试被中断。没有继续重建会话或重跑矩阵。

本轮结论仅为设置入口外观和一级菜单结构已确认；后续动作因交互环境不稳定保持未验证。没有修改实现或数据。
