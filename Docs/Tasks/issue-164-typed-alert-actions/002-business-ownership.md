# 业务提示按功能归属

- 关联：[独立 Action 方案](000-plan.md)、[原实现与验证结果](001-result.md)
- 日期：2026-10-24
- 实现前基线：`dc76f6b5a531ff93fa90a23e7598c1440b318de0`
- 状态：实现完成，构建与自动化检查通过

## 目标与决策

根配置原先同时构建设置清理、下载错误和 DEBUG 提示，并将业务动作交给 `CalendarHomeCoordinator`。本次将内容、依赖适配与动作处理归回对应功能，保留强类型路由、独立 Action 和统一宿主。

- `Settings/CalendarSettingsAlerts.swift` 负责清理确认、成功／失败内容，以及等待清理完成后提交结果提示；`ClearDownloadedDataAction` 同目录维护。
- `App/Store/CalendarDownloadAlerts.swift` 负责下载错误内容与向当前最上层提交错误提示。下载失败不依赖某个页面仍然存在。
- `Debug/CalendarDebugAlerts.swift` 负责调试通知和导航选项；直接接收所需 Router，不依赖 Home coordinator。
- `Shared/CalendarNoticeAlert.swift` 与 `CalendarNoticeAction` 只复用单个确认按钮的内容和空操作，不包含业务路由、错误映射或流程。
- `CalendarNavigationConfiguration.alert` 仅按路由分发至这些定义；根层继续注入长期业务依赖。`CalendarAlert` 保留为导航树的路由集合，不增加 package 或 target。
- 清理仍由 `ChineseCalendarStoreCoordinator` 执行。handler 使用发起提示所在层的 presentation，保持 `await` 链；不新增 View 局部 alert 状态、Task 或业务会话注册表。
- 根宿主仍位于数据库切换会重建的页面之外，Core 的真实关闭回调、异步门槛、提示队列和外部导航协调不变。

依据：[导航规范 NAV-02、NAV-03、NAV-04](../../Conventions/Navigation.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[本地化规范](../../Conventions/Localization.md)。

## 验收标准

| ID | 要求 | 验证方式 |
| --- | --- | --- |
| OWN-01 | 根配置只分发，Home coordinator 不处理具体 alert 业务；定义和 Action 按功能归属 | 源码和引用检查 |
| OWN-02 | 清理取消、成功、失败、缺少 store 和已失效 context 的行为保持 | 迁移已有业务动作测试 |
| OWN-03 | 各提示文案、按钮角色、独立 Action 与 DEBUG 导航行为保持 | 现有内容、配置和动作测试 |
| OWN-04 | 统一宿主、排队、真实关闭及异步门槛保持，App 与测试可构建 | 原生 Xcode 测试、format、strict lint、本地化检查 |

## 实施与验证结果

按方案完成，未修改 `NavigationCore`、路由集合、系统宿主、清理实现或用户可见文案。原 `CalendarAlertContent` 与 `CalendarHomeCoordinator+Alerts` 已移除，设置、下载和 DEBUG 各自配对内容与 handler，普通确认按钮共用 `CalendarNoticeAlert`。

错误提示现在直接接收 `CalendarStoreFailure`，由所属业务选择恢复文案；原生产调用链一直传入非空映射结果，因此移除只在旧内容辅助函数中存在的 nil message 分支。测试相应使用 `.clear`／`.download` 的业务失败值。

本次证据绑定未提交工作区：363 个现存 Swift 文件的路径与内容摘要合并 SHA-256 为 `88daee132bc180458047817bb2266f6d4bed97037d398a987284b1e65c953aaa`，算法、基线及变更文件摘要见 [validation-summary.json](evidence/business-ownership/validation-summary.json)。

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| OWN-01 | 已验证 | 根配置每个 case 只调用所属业务；旧集中定义与 Home handler 无生产引用，Core 无改动 |
| OWN-02 | 已验证 | `CalendarAlertActionTests` 的取消、成功、失败、无 store、失效 context 用例全部通过 |
| OWN-03 | 已验证 | 内容、配置、动作三组共 13 次测试执行通过，含两个错误路由参数和 DEBUG 导航行为 |
| OWN-04 | 已验证 | 原生 Xcode 构建成功；`RunAllTests` 489 次执行全部通过，0 failure／skip／notRun；format 360 文件、strict lint 347 文件无问题，本地化 337 项资源检查通过 |

测试使用本 worktree 的 `ChineseCalendar.xcodeproj`、`ChineseCalendar-iOS` scheme 和配置指定的 `chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`）。测试摘要及相关用例记录见 [xcode-tests.json](evidence/business-ownership/xcode-tests.json)。

本次保留并迁移既有行为测试，没有为文件拆分增加镜像实现的测试。未运行完整专项 review、手动 Simulator 点击或真机验证；原结果中的交互证据属于原代码状态，不作为本次改动的交互验证。

## 合入远端 main 后的验证

在 `codex/feature-owned-alerts` 分支提交实现，并将远端 `main` 的 4 个后续提交合入至 `fda693b8def766c4126b7fc8d2edcc008bbf8eef`；合入的 main 为 `8bb52e64181dd5365a07b28638f1f98b32ebf146`，没有冲突。后续提交涉及原生 SwiftUI 截图策略、旧入口清理和 Store Preview，没有改变本次 alert 调用的清理方法或宿主生命周期。

合并后的原生 Xcode 业务／导航测试 489 次执行全部通过；独立 `ChineseCalendarSnapshots` 比较 scheme 的 4 组测试、23 张基准也全部通过，未重录或修改基准。首次快照构建发现被忽略的本地生成工程仍引用远端已删除的 `SnapshotRenderer.swift`，使用 `xcodegen generate` 按现有 `project.yml` 更新工程后重试通过，无需修改产品源码。

format 检查 359 个文件、strict lint 检查 346 个文件均通过；本地化检查覆盖合并后的 335 项资源和 21 个剩余生产字符串。362 个现存 Swift 文件的合并摘要为 `62f43259ceffb83d88f0977f4622b1eff9a755a6844e5b3920d9accd2e4183d2`。环境、测试结果和代码版本见 [after-main-sync.json](evidence/business-ownership/after-main-sync.json)。远程 CI 以 PR 当前检查状态为准。
