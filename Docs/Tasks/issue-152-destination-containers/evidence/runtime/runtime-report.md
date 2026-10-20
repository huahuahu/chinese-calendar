# Issue #152 Simulator 运行验证

日期：2026-10-19；工具：原生 Xcode MCP + device-interaction skill。
设备：`chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。
项目：本工作树 `ChineseCalendar.xcodeproj`；scheme：`ChineseCalendar-iOS`。

## 首轮构建观察（修复前）

通过 `DeviceInteractionInstallAndRun` 安装当前实现，进程 PID 96003。以下证据属于修复前构建，不代表最终版本全部通过。

| 场景 | 实际观察 | 证据 |
| --- | --- | --- |
| 根 Tab | 日历、朝代、设置均正常显示内容，单条导航栏 | 初次截图在工具产物，后续 `01`–`04` |
| 设置 Push | 从调试操作进入测试页，depth 1；再次 Push，depth 2 | `01-settings-debug.*`、`02-settings-depth-two.*` |
| Tab 路径保留 | depth 2 页面 ID `3F04E419-C113-47EC-96D7-4494DE39BDA6`，切到朝代进入秦详情，再回设置后 ID 和 depth 不变 | `03-history-detail.*`、`04-tab-preserved.*` |
| Pop | 导航栏返回从 depth 2 回到 depth 1 原 ID `39091E54-996E-488C-A0AE-DB3A1B5D52F1`，再次返回设置根页 | 工具层级已实际读取 |
| 下载预览两个 Tab | 第一 Tab 显示进度场景，第二 Tab 显示切换检查，底部附件保留准备下载阶段 | `05-download-double-close.*`、`06-download-second-tab.*` |
| 下载关闭入口 | 第一 Tab 左上“关闭”和右上“完成”同时出现；已报告主代理 | `05-download-double-close.*` |
| 子下载详情 | 第二 Tab 的底部附件打开详情，显示五阶段与单个关闭按钮 | `07-download-child-detail.*` |
| 子详情关闭 | 点右上关闭后 App 崩溃，`NavigationLayerContent.swift:35` 触发 `A routed navigation stack requires a root Destination.` | `08-old-build-child-dismiss-crash.png/.txt/.log` |

另：打开子下载详情时日志出现 `Update NavigationRequestObserver tried to update multiple times per frame.`；目前未单独归因为用户可见缺陷。

## 修复后交互验证

第二轮在关闭竞态和双关闭按钮修复后重新安装。该轮与最终源码的差异仅为主代理随后进行的 `showsDismissButton` 条件提取、snapshot restore 校验表达式调整。不能把这一轮称为最终源码指纹的全部交互覆盖。

| 场景 | 结果 | 证据 |
| --- | --- | --- |
| 下载两个 Tab 与会话状态 | 第一 Tab 仅“完成”；选择 50% 后切换第二 Tab，附件仍为 50%；子详情关闭后回同一第二 Tab，App Running | `09`–`11` |
| 普通 sheet Push / Pop | sheet 根 depth 0 / ID `CC7510B0-E0A0-4EA4-937F-50F65BA4754F`；Push depth 1 后返回，恢复原根 ID | `12-sheet-root.*`，Push/Pop 过程层级已读取 |
| 嵌套 fullScreen 关闭再开 | sheet 内打开全屏，根 depth 0 / ID `CE206E2A-AA0D-4D6F-BB9E-A664F6F8D785`；关闭返回原 sheet；重开得到新 ID `D816E2A6-B255-4DF4-B22D-F0EB547AA793` | `13`–`14` |
| Alert 排队 | 业务提示 1，点“好”后才显示业务提示 2，再关闭回同一全屏页 | `15`–`16` |
| Deep Link 取消 | 在嵌套全屏页点击“模拟打开今年的 Deep Link”，出现离开确认；选择留在当前页面，保留全屏页与原 ID | `17`–`18` |
| Deep Link 批准 | 再次打开并选择“关闭并前往”，整个 sheet/fullScreen 链消失，进入日历 Tab 的 2026 年页面 | `19-deeplink-approved.*` |

## 最终源码回归

约 22:45 再次 `DeviceInteractionInstallAndRun`，对应 `../source-manifest.json` 的源码指纹 `120cfdd26069afa7593ac0a3b60eaaacadc095dc3409e5818a755b7b0a15f93c`，base commit `4f386d06d9a0e4b2b248ea83a3604dc08fc5ae1f`。会话失效后 22:59 再次原生安装同一最终源码，完成剩余 Alert 协调验证。

| 场景 | 结果 | 证据 |
| --- | --- | --- |
| 根 Tab 与路径保留 | 朝代进入秦详情，切到设置再回朝代，保留秦详情与返回按钮，单条导航栏 | `20-final-history-detail.*`、`21-final-tab-path-preserved.*` |
| 最终下载关闭回归 | 第一 Tab 单个完成按钮；第二 Tab 打开子详情，关闭后回第二 Tab，App Running；切回第一 Tab，完成返回设置 | `22-final-download-root.*`、`23-final-child-dismiss.*` |
| 业务 Alert 期间提交外部导航 | 最终 sheet 内点击“Alert 期间请求跳转历史”：先出现业务提示 1；关闭后才出现“离开当前页面？”；确认后 sheet 消失，朝代 Tab 新测试页 depth 1，App Running | `24`–`26` |

上述稳定画面未观察到重复导航栏、文本重叠、不可读文字或错误容器嵌套。模态关闭和 Alert 切换的即时快照有短暂空白/动画中间态；重新采集后稳定，不记为持久 UI 缺陷。

最终日志仍有 `Update NavigationRequestObserver tried to update multiple times per frame.`（`26-final-alert-navigation-done.log:625`），未伴随上述流程失效或新崩溃；保留诊断，不把它归为已修复的问题。

## 原生 Preview

`RenderPreview` 使用 Xcode 包节点路径 `ChineseCalendarSources/ChineseCalendarUI/PreviewSupport/FullStoreDownloadPreview.swift`（文件系统路径无法被该工具解析）。工具返回 `displayName=底部下载进度`、`errors=[]`，source line 41，快照 `27-native-download-preview.png`。

Preview 管线自行选择 **iPhone Duo / iOS 27.1**，与交互使用的 iPhone 18 Pro Max / iOS 27.0 不同；工作区 active destination 复查仍是配置的 `chinesedate iPhone 18 Pro Max (885f)`。生成快照中模态内容位于画面底部、画面上半部为空白，可能捕获了模态呈现中间态。只确认 Preview 编译/生成快照成功，**不宣称完整视觉验证通过**。未重复渲染或扩展 Duo 布局矩阵。

主代理后续补充（23:11）：最终 300 项测试通过后，以同一路径和参数重试一次 `RenderPreview`，仍为 iPhone Duo / iOS 27.1、`errors=[]`，但快照近乎空白，完整 Preview 视觉仍未验证。未改动生产源码，也未继续扩展设备矩阵。见 [28-native-download-preview-retry.png](28-native-download-preview-retry.png) 和 [工具结果](28-native-download-preview-retry.json)。

## 验证边界与会话清理

- 下载预览没有可操作的 Tab 内 Push 控件；两个下载 Tab 的 Push 隔离由主代理结构测试覆盖，本次只实测 Tab 切换、状态保留与嵌套详情。
- Deep Link 使用现有 DEBUG 模拟入口；未从 Safari / 系统实际打开 URL。
- 未测试实体设备、横屏、Dynamic Type 全矩阵、系统交互式拖拽关闭与后台恢复。
- 首轮关闭断言崩溃已实际复现并保存；最终源码相同路径已通过。没有把旧构建全部结果直接计为最终通过。
- 原生会话两次返回不存在：一次发生在首轮崩溃后；一次最终回归期间会话失效且 App 被停止。重建一次工作区会话后恢复，未更换设备、未修改全局 Git、未使用直接 simctl。
- 最终交互 session `Verify Issue 152 Alert Final` 已通过 `DeviceInteractionEndSession` 返回 `Session stopped`。前两个已失效会话无可结束资源。Xcode/Simulator 已交回主代理进行最终全套测试。
