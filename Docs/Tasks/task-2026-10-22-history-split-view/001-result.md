# 历史页原生三栏：结果

- 方案：[000-plan.md](000-plan.md)
- 记录日期：2026-10-22
- 状态：实现、计划验收与合并前专项审查完成；验证边界见下文。
- 代码状态：基于 `10298146936635f1cb7e4f1cc1a26fd5ba84c18e` 的任务工作区快照。本记录封存提交前的源码、测试与交互证据；后续提交、远端 CI 和合并状态以关联 PR 为准。
- 提交前同步：工作分支已 fast-forward 到 `b347895e`；新增上游提交仅整理 NavigationCore 目录与 README，Swift 文件内容不变。定向复验、一次未复现观察与证据边界见 [002-premerge-verification.md](002-premerge-verification.md)。
- 最终源码快照：本轮 `ChineseCalendarUI` 与 `ChineseCalendarLocalization` 下 22 个修改／新增文件，按相对路径排序，以「路径、NUL、文件字节、NUL」串联计算 SHA-256，结果为 `9d63e91b24777701928d92d42f20b649731122f860b23f18495552de026c680a`，详见 [最终源码指纹](evidence/source-snapshot-final.txt)。此指纹包含测试，不包含文档和截图。
- 初轮 iPhone／iPad 及修复前热链接使用 [初轮源码指纹](evidence/source-snapshot.txt)，组合值为 `5daaccff6f4b0a1d63d5315dc7733a2c65450e1bbad2965859409483c4682279`。其后仅修正皇帝深链接根、对应状态与 builder、确认文案映射及测试；三栏布局、年号导航和朝代链接没有改变。最终修复在配置 iPhone 上重新构建并复验。

## 实际结果与方案边界

正式历史 Tab 已采用一个原生 `NavigationSplitView`，依次组织正统时间线、朝代资料入口和具体内容。初始进入保留空选择。前两栏用选择列表表达上下游关系，最后一栏由 `NavigationScopeView` 提供唯一的详情栈；`Sources/NavigationCore` 本轮没有改动。

主 Tab 在 `.mainTabs` Destination 构建的页面结构中使用所在层 `.scope(.history)` 详情栈；独立历史容器由 `.historyHome` 描述，通过 `presentHistory(style:)` 声明 `.primary: .historyEmpty` 根。详情内容继续由统一 Destination builder 构建。这里的接入范围不构成任意普通 push 嵌套容器的交互支持声明；Router 可以存入某个 Destination 值，也不能单独证明对应界面具备正确的宿主与栈配置。边界沿用 [NAV-06／NAV-07](../../Conventions/Navigation.md)。

`CalendarHistoryState` 从 `.historyDetail(orthodoxPeriodID:section:)` 或 `.historyEmperor(orthodoxPeriodID:emperorID:)` 投影时期和资料选择，不额外保存第二份 selection。`.historyEmpty` 表达未选择，资料种类包括皇帝、年号和正统时间跨度。切换时期清空资料选择及 path；切换资料替换详情根并清空 path；同一资料根重复选择保留已有 path。选择和布局更新先检查 Context 是否接受修改，确认、alert 和关闭事务期间不提前改变业务选择。

外部朝代链接通过 `.setRoot(.historyDetail(..., section: nil))` 应用到历史栈。皇帝链接先通过 `.setRoot(.emperor(...))` 完成既有确认和关闭协调，再由页面查询当前数据库，解析对应的默认正统传统时期；状态只接收稳定 ID，并在根仍匹配该皇帝时替换为 `.historyEmperor`。旧查询结果不能覆盖已被新请求替换的根。

交互中发现并修复 HS-F01：初次实现先换成帝王列表根，再补入皇帝详情 path，iPhone 稳定后停在列表。改用带父级身份的皇帝详情根后，不再人工插入列表导航。冷启动已实际进入王莽详情，返回新朝资料入口，点击帝王打开只读列表。原始失败见 [修复前截图](evidence/deeplink-emperor-unexpected-list.png)。未采集 SwiftUI 内部 path 写回日志，因此不将具体系统内部机制当作已证实根因；也没有增加延时或修改 NavigationCore。

Coordinator 按详情 Context 的对象身份复用历史状态，保留栏布局，关闭后统一清理失效缓存。原有皇帝列表、年号列表、年号详情和正统跨度页面继续复用；空态文案集中在本地化模块。

主要实现位置：

- [CalendarHistoryHomeView](../../../Sources/ChineseCalendarUI/History/Timeline/CalendarHistoryHomeView.swift)、[CalendarHistorySidebarView](../../../Sources/ChineseCalendarUI/History/Timeline/CalendarHistorySidebarView.swift)：分栏组合与时间线选择。
- [CalendarHistoryContentView](../../../Sources/ChineseCalendarUI/History/DynastyDetail/CalendarHistoryContentView.swift)、[CalendarHistoryDetailView](../../../Sources/ChineseCalendarUI/History/DynastyDetail/CalendarHistoryDetailView.swift)：资料入口和现有内容复用。
- [CalendarHistoryState](../../../Sources/ChineseCalendarUI/History/Navigation/CalendarHistoryState.swift)、[CalendarRouter](../../../Sources/ChineseCalendarUI/Home/Navigation/CalendarRouter.swift)、[CalendarHomeCoordinator](../../../Sources/ChineseCalendarUI/Home/CalendarHomeCoordinator.swift)：选择投影、外部请求与 Context 生命周期。
- [CalendarHistoryStateTests](../../../Sources/ChineseCalendarUI/Tests/CalendarHistoryStateTests.swift)：11 项新增状态测试；既有 Router、presentation 和导航 Context 测试同步新的根路由语义。

## 验收证据

最终在配置 iPhone Simulator 上执行原生 Xcode MCP `BuildProject(buildForTesting: true)` 成功；随后针对性测试覆盖 61 个函数，结构化结果 67 条通过、0 失败。由于选择性运行对部分参数化测试只执行了一个参数，继续执行 `RunAllTests`：**402 项全部通过，0 失败、0 跳过、0 未运行**。最终依据为 [结构化测试汇总](evidence/tests-final.json) 和 [控制台摘录](evidence/tests-final-console.txt)，覆盖新增 11 项历史状态测试。

初测的 59 个函数控制台通过，见 [tests-initial.txt](evidence/tests-initial.txt)，但动态 UUID 参数曾导致 `No result` 汇总条目。已将 fixture 改为固定 UUID；修复后的第一次选择性运行仍混入旧参数条目，重新构建测试目标并运行全套后最终汇总没有未运行项。初测摘要不作为最终测试通过的依据。

| 验收项 | 状态 | 证据与覆盖范围 |
| --- | --- | --- |
| HS-01：宽窗口三栏，窄窗口逐级打开与返回 | 已验证 | iPhone 竖屏完成时间线 → 西汉资料 → 年号列表 → 前元详情，再连续系统返回到时间线。iPad 横竖屏均同时显示三栏，旋转保留选择和详情，见下方记录。 |
| HS-02：上游清路径、重复选择保留路径、空选择无残留 | 已验证 | iPhone 切到新后无西汉残留，并能重新打开同一资料和朝代。iPad 在前元详情中重选西汉／年号保留详情；切中栏帝王替换右栏；直接切左栏新后清除资料选择和旧详情。最终状态测试覆盖清空、重复选择与 alert 门禁。 |
| HS-03：年号详情在详情栈 push/pop，返回后重新选择 | 已验证 | iPhone 前元详情可逐级返回，随后选择新并打开各资料；iPad 仅右栏 push 前元，左右两栏保持可操作，切换后可重新进入年号详情。 |
| HS-04：朝代／皇帝链接与确认、取消、真实关闭协调 | 已验证 | 状态测试覆盖确认取消、批准但尚未关闭、关闭完成、解析时机与旧结果丢弃。实际热链接定位西汉；修复后冷启动参数与热链接均直接打开王莽详情；sheet 中取消保持原页，确认后关闭并打开目标。UI 证据证明最终页面，内部关闭回调的时序约束由状态测试验证。 |
| HS-05：Tab／模态隔离、旧 Context 失效、数据库替换保留路由 | 已验证（状态测试为主） | `rootIsTheOnlySelectionSourceAcrossTabAndStoreChanges` 与 `modalHistoryKeepsIndependentStateAndReleasesItAfterDismissal` 在最终全套测试中通过。iPhone 切至日历再回历史保留新朝代起讫页，见 [Tab 返回状态](evidence/iphone-tab-state-retained.png)。数据库替换和独立历史模态的结论来自状态测试，不代替设备交互。 |
| HS-06：构建、针对性测试、格式、严格 lint、本地化校验 | 已验证 | `ChineseCalendar-iOS` 的 Debug Simulator 构建成功，原生工具在 iPhone／iPad 安装运行成功；最终全套 402 项通过。最终源码执行 `./Scripts/format.sh --check`：304 文件、0 个需格式化；`./Scripts/lint.sh`：293 文件、0 violation；`python3 Scripts/validate_localized_copy.py`：337 项通过；`git diff --check` 通过。 |

### iPhone 窄屏交互记录

- 环境：`chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，竖屏 440 × 956 pt。
- 工具：原生 Xcode MCP `DeviceInteractionSynthesize`；会话 `History Three Column Verify`，2026-10-22 18:04–18:07（设备显示时间）。沿用已安装的新构建，App PID 为 25567，采集时均处于 `Running`。
- 操作按每一步的新截图和 AX hierarchy 的 hit point 执行。原始本机操作报告位于 `.output/history-split/iphone-interaction-report.md`；下面保留可随任务文档交付的关键截图和结果，不依赖该临时路径作为唯一证据。

| 路径 | 实际结果 | 关键截图 |
| --- | --- | --- |
| 日历 → 历史 Tab | 首次进入时间线，无默认朝代选择 | [首次时间线](evidence/iphone-initial-timeline.png) |
| 西汉 → 资料入口 | 显示皇帝 13、年号 43、朝代起讫前206—8 | [西汉资料入口](evidence/iphone-western-han-categories.png) |
| 西汉 → 年号 → 前元 | 列表显示 43 个年号，前元详情显示前179—前164、刘恒·文帝及纪年边界；系统返回可逐级回到列表、资料入口和时间线 | [年号列表](evidence/iphone-western-han-era-list.png)、[前元详情](evidence/iphone-era-detail.png) |
| 返回时间线 → 新 → 年号 | 列表仅始建国、天凤、地皇，皇帝为王莽，没有西汉旧内容；返回后可重新打开相同资料和朝代 | [新朝代年号](evidence/iphone-changed-dynasty-era-list.png)、[重新选择](evidence/iphone-reselect-same-dynasty.png) |
| 新 → 皇帝／朝代起讫 | 皇帝页显示王莽和 3 个年号；跨度页显示 8—23、自称与正统期、边界事件 | [皇帝列表](evidence/iphone-emperors.png)、[正统跨度](evidence/iphone-orthodox-period.png) |
| 新朝代起讫 → 日历 Tab → 历史 Tab | 原资料页和返回关系保留 | [Tab 状态保留](evidence/iphone-tab-state-retained.png) |

上述路径未观察到无响应、崩溃、错误返回层级、旧朝代内容残留或明显文字重叠／截断。这是已执行路径的交互结论，不覆盖 VoiceOver、Dynamic Type、真机和跨启动恢复。

### iPad 三栏交互记录

环境为 `iPad Pro 13-inch (M5)`、iPadOS 26.5，UUID `2D15C1CC-968A-4A02-B13A-20166E188204`。原生 Xcode MCP `RunProject` 成功构建并启动 App；原生交互工具没有列出此设备，回退 XcodeBuildMCP。后者可读截图和 hierarchy，但两次点击返回成功而画面未变，因此实际交互改用 CUA 的 Device Hub（`com.apple.dt.Devices`），逐步核对最新 AX 与截图。XcodeBuildMCP 用于捕获关键截图，临时 defaults 已恢复，未改持久配置。

| 路径 | 实际结果 | 关键截图 |
| --- | --- | --- |
| 首次进入历史 Tab | 竖屏同时显示时间线、中栏选择朝代、右栏选择历史资料 | [初始三栏](evidence/ipad-initial-three-columns.jpg) |
| 西汉 → 年号 → 前元，旋转为横屏 | 只有右栏进入详情，左右选择保留；重选西汉或年号不退出详情 | [横屏前元详情](evidence/ipad-landscape-era-detail.jpg) |
| 前元详情 → 中栏帝王 | 右栏替换为帝王列表，旧详情清除；可再次选年号进入前元 | 同轮 AX 与画面逐步核对 |
| 前元详情 → 左栏新 | 中栏更新为帝王1／年号3，资料选择清空，右栏回空态且旧返回按钮消失 | [切朝代清空详情](evidence/ipad-change-dynasty-clears-detail.jpg) |
| 新 → 年号 → 始建国，再次旋转为竖屏 | 三栏选择和始建国详情保留，没有西汉内容残留 | [旋转后保留详情](evidence/ipad-portrait-detail-retained.jpg) |

没有观察到所测路径的明显重叠、截断、崩溃或错误选择。截图为工具返回的压缩 JPEG，实际操作同时核对完整 Device Hub 画面；未测试 Stage Manager 任意缩放和分屏窗口。

### 深链接与确认交互记录

使用同一配置 iPhone。修复前的非 workspace 会话通过 App 截图、AX 和 PID 31448 验证；修复后 `History Deep Link Fix` 会话 PID 33611、全部捕获为 `Running`。冷启动使用 `DeviceInteractionInstallAndRun` 的 `--deep-link chinesecalendar://emperor/xin_emperor_0000` 参数；两 MCP 没有 openURL 操作，热链接使用本地 `xcrun simctl openurl`。未验证进程关闭时由操作系统 URL 唤起的完整链路。

| 路径 | 实际结果 | 关键截图 |
| --- | --- | --- |
| 西汉朝代热链接 | 定位西汉资料入口，13 位皇帝／43 个年号 | [朝代链接](evidence/deeplink-western-han-category.png) |
| sheet 内始建国详情 → 西汉链接 → 留在当前页面 | 确认取消，原 sheet 及详情保留 | [取消保留详情](evidence/deeplink-sheet-cancel-stays.png) |
| 重发西汉链接 → 关闭并前往 | sheet 与 alert 消失，根层显示西汉资料入口 | [确认后西汉](evidence/deeplink-sheet-confirmed-western-han.png) |
| 修复后冷启动皇帝链接 | 直接显示王莽详情，系统返回新朝资料入口；帝王入口仍打开原只读列表 | [冷启动王莽](evidence/deeplink-fixed-cold-emperor.png)、[返回新](evidence/deeplink-fixed-cold-back-xin.png)、[帝王列表](evidence/deeplink-fixed-readonly-emperor-list.png) |
| 西汉资料入口 → 王莽热链接 | 直接显示王莽详情，返回标签为新 | [热链接王莽](evidence/deeplink-fixed-hot-emperor.png) |
| 年号 sheet → 王莽链接 → 确认 | 关闭 sheet 和 alert，根层直接显示王莽详情 | [皇帝确认](evidence/deeplink-fixed-emperor-sheet-confirm.png)、[确认后王莽](evidence/deeplink-fixed-sheet-to-emperor-stable.png) |
| 修复后新 → 年号 → 始建国 → 返回年号 → 返回新 | 普通 push/pop 正常，无皇帝详情或 sheet 残留 | [年号详情](evidence/deeplink-fixed-ordinary-year-detail.png)、[返回资料入口](evidence/deeplink-fixed-ordinary-pop-category.png) |

HS-F01 已修复并实测通过。既有帝王列表的卡片只展示资料、没有详情跳转，本轮保持其行为；皇帝详情原有来源说明文字也未在此导航任务中修改。

## 审查结论与剩余事项

2026-10-22 执行正式 `review-changes`，运行标识 `history-three-columns-premerge-20261022-01/round-01`。领域／导航、SwiftUI／文案、数据／并发三个独立专项均完成，协调者逐份核验报告与关键源码；未确认范围内可执行缺陷或强制规范违规。审查的 60 个任务文件均与起始快照一致，22 个源码／测试文件仍匹配上述最终指纹与 402 项测试结果。审查后只补充本结果与定向交互证据，没有修改产品源码。

实现边界核对确认 NavigationCore 未改动；数据查询留在历史页面，路由只保存稳定身份。HS-F01 保持 `fixed-and-verified`。普通 push 容器的结构测试不作为完整界面支持证据。store identity 测试验证稳定路由与状态保留，没有在渲染页面中实际切换两套 SwiftData 容器；相关生命周期结论另有源码追踪支持。最终皇帝根修正已在 iPhone 复验，未单独在 iPad 复验。

导航审查提出「系统返回时间线后再收到相同朝代链接，可能因根值相同而不移动紧凑栏」的待验证假设。定向使用同一配置 iPhone，实际完成西汉资料入口 → 系统返回时间线 → 重发 `chinesecalendar://dynasty/orthodox_sequence_qin_han_to_prc_western_han`，稳定页面重新显示西汉、帝王 13 与年号 43。该场景未复现假设中的故障，因此不列为缺陷；不据外部页面推断 SwiftUI 内部 Binding 写回机制。

同一皇帝链接在返回新朝资料入口后重开也通过。另一次首次跨 Tab 链接曾落到时间线，随后当前源码重新构建、两次全新启动并各仅发送一次 URL 均正确进入资料入口；未确认为可重复缺陷，保留观察与日志警告，不声称覆盖全部时序。具体结果见上述 002 记录。

未运行 Preview、真机、VoiceOver、Dynamic Type、任意窗口缩放或跨启动状态恢复验证；本记录不将本地审查等同于远程 CI、合并或发布。原生 Xcode 目标与临时 XcodeBuildMCP defaults 使用仓库配置手机，`.xcodebuildmcp/config.yaml` 未修改。
