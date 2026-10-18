# Issue #145：实施后的导航入口与状态归属

与 [方案](000-plan.md) 的基线表对应，已按 [局部 Router 与数据驱动宿主方案](006-scoped-router-plan.md) 更新。路径除 `NavigationCore` 外相对于 `Sources/ChineseCalendarUI/`；本表描述源码接入，实际交互证据见结果记录。

| App 入口／宿主 | 唯一结构状态来源 | 处理与依据 |
| --- | --- | --- |
| `Home/CalendarHomeTabView.swift` 日历／历史栈 | `NavigationScopeView` → 各 Tab context → `NavigationRouter.paths` | 三个 Tab 均独立，由通用宿主注册 destination。NAV-01／04 |
| `History/Timeline/CalendarHistoryHomeView.swift` 朝代卡 | `NavigationLink(value: .dynasty(orthodoxPeriodID:))` → 所在 path | 保留稳定正统时间 ID。NAV-02／04 |
| `History/Shared/DynastyFactCard.swift` 三类资料卡 | `navigation.push(model.destination)` → 当前 context path | Tab 与模态复用同一组件，长按菜单可继续嵌套 sheet/full-screen。NAV-04 |
| `History/ReignEraList/ReignEraListView.swift` 年号卡 | `NavigationLink(value: .reignEra(reignEraID:))` → 所在 path | 保留。NAV-04 |
| `Home/Navigation/CalendarPresentationMenu.swift` | 当前 context 的子 presentation | 历史朝代行和资料卡的真实模态入口，present 只传数据。NAV-01／02／03 |
| `Home/Navigation/CalendarNavigationHost.swift` 根 sheet/full-screen | `CalendarHomeCoordinator.router.navigation` | 根 App 的 owner 和宿主位于 `.id(storeIdentity)` 外；公开主页与纯 Preview 使用自己的明确宿主。NAV-01／03 |
| `Home/Navigation/CalendarPresentedDestinationView.swift` 业务 builder | Core context 引用的原树 | 只提供业务页面和数据环境，`navigationPresentations` 统一提供根与递归宿主。旧业务节点宿主已删除。NAV-04／06 |
| `Calendar/Month/YearMonthHeader.swift` 年份入口 | `.yearPicker(sessionID:)` 对应的 presentation 节点 | 已移除局部 Boolean、sheet、独立栈。日历 feature 保留 selection 和过渡状态；UI 会话传递原 ModelContext、selection 和结果回调。NAV-01／02／03 |
| `App/ChineseCalendarRootView.swift` 下载附件 | `.downloadDetails` 对应的 presentation 节点 | 已移除局部 Boolean/sheet；宿主监听实时 coordinator 进度，nil 时精确移除下载节点。NAV-01／03／05 |
| `App/Store/FullStoreDownloadDetailView.swift` | 由 presentation host 提供栈和关闭动作 | 内容不再重复建栈；独立 `#Preview` 自己提供容器。NAV-06 |
| `Settings/CalendarSettingsView.swift` 下载演示入口 | `.downloadPreview(sessionID:)` full-screen | 已移除局部 Boolean/fullScreenCover，真实 App DEBUG 入口纳入同一棵树。NAV-01 |
| `PreviewSupport/FullStoreDownloadPreview.swift` 演示详情 | 演示节点的 `.downloadPreviewDetails(sessionID:)` 子 sheet | 已移除局部 Boolean/sheet；阶段与字号由 `FullStoreDownloadPreviewState` 提供给父子页面。NAV-02／03／05 |
| 演示内两个 Tab 的 NavigationStack | 无页面 push，仅提供各 Tab 导航栏／真实 Tab 附件布局 | 明确的容器例外。业务宿主读取 `usesPresentationNavigationStack: false`；子模态仍由框架节点承载。新增 Tab 内 push 时需接入节点或专有 scope path。NAV-04／06 |
| 设置 Tab 的 `NavigationScopeView` | `.settings` scope path | 与日历、历史使用同一公开框架能力。NAV-04 |
| 根下载错误 alert、设置清除 confirmationDialog／结果 alert | 原 View/coordinator 的交互状态 | 非页面导航，保留。NAV-04 |
| `CalendarSettingsView.showsDoneButton` 的环境 dismiss | 调用方提供的呈现环境 | App 唯一调用方传 `false`，没有新增独立设置模态。不能将该声明当作绕过 Router 的证据。NAV-05 |
| 根 URL／冷启动 deep link | `CalendarHomeCoordinator` → `CalendarRouter` → `NavigationRouter.submit` | owner 跨数据页面重建；模态上先确认；批准后等根关闭完成，冷启动只处理一次。NAV-03／05 |

独立 Preview 容器覆盖：`CalendarPageView`、`YearMonthHeader`、`CalendarYearPickerView`、月条、日格／日格 cell／布局、日期详情组件、历史各页及 `DynastyFactCard`。`LunarMonthStripPreviewContent` 和日格的 Preview helper 只有 Preview 调用；`SampleDataPreviewHost` 统一注入独立业务导航上下文。下载演示不是目录豁免，已按上表迁移。

所有页面关闭动作归属：年份取消和通用页面使用环境中当前 context 的 dismiss；选年由 coordinator 精确移除 picker；下载详情沿用右侧关闭按钮但动作由宿主提供；演示“完成”关闭当前 full-screen；子详情关闭只改子节点；系统下滑写回同一绑定。根完成通知统一完成 Core 的延迟请求；业务层不另设手动关闭窗口。子完成通知只清理已退出的业务上下文。

本次盘点没有发现页面级 popover。`NavigationCore` 仍只依赖 Foundation、Observation、SwiftUI 和日志模块，没有日历／SwiftData 数据访问。
