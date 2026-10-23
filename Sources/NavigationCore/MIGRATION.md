# NavigationCore 迁移说明

本文供已经接入旧 API 的调用方升级。第一次使用请从 [README](README.md) 的最小示例开始；当前项目规则以[导航规范](../../Docs/Conventions/Navigation.md)为准。

下面按需要改动的接口组织，目标都是当前 API。历史任务记录解释当时的决策和验证范围，其中的中间方案可能已经被后续设计替代。

## 迁移到发起方所有权与单次结束通知

Issue #165 将业务资源所有权归还发起方，并以本次呈现的结束通知替代全局导航扫描。下面列出调用方的迁移方式；测试环境、运行结果和覆盖边界统一记录在[结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)。

| 旧接法 | 当前接法 |
| --- | --- |
| `present`／`presentAlert` 直接返回呈现结果 | 返回 `NavigationPresentationSubmission`；判断改为 `.result.isAccepted`，接受时保存可选 `handle` |
| 从节点 ID 查找并关闭本次页面 | 保存本次 `NavigationPresentationHandle`，调用 `dismiss()`；该方法仍返回 `NavigationPresentationResult` |
| 全树配置按 sessionID 回查业务字典 | 在提交时传 `configuration:`，直接引用具体 feature／session，仍由既有 `destination(for:)` 构建 |
| 根宿主扫描保留路由、alert 路由及会话登记 | 提交时绑定本次 `onFinish`；拒绝按同步结果回滚，接受后由回调最终清理 |
| 用 `isActive`、节点消失、`onDisappear` 推算业务释放 | 导航可否修改看命令结果，资源何时结束看本次 `onFinish` |
| App 测试手动通知系统关闭完成 | 普通 `import NavigationCore`，App-hosted 测试目标中的实际 builder + 真实前台 scene／宿主 + 释放探针 |

先由来源 feature 准备并持有资源，再提交；例如年份流程调用 `CalendarYearFeature.presentYearPicker`，本次配置由 `CalendarHomeCoordinator.yearPickerConfiguration` 构造。配置捕获具体 session 和正确来源 feature，不动态查全局 `currentSession`。Session 不保存强捕获 feature 的结果闭包。

`onFinish` 为 `@MainActor () -> Void`，属于单次请求，不加入根配置协议。拒绝不回调；已接受请求恰好结束一次；排队或系统尚未接手的请求取消后直接结束；已接手请求等真实关闭，alert 还需等按钮异步 handler 完成。来源的清理方法核对本次资源，避免旧回调清空新流程。handle 只提供 `dismiss()`，不暴露 ID、节点或状态，不保活 Router；释放 handle 不等于取消。

按次配置与 `onFinish` 保存在 SwiftUI 宿主的 `NavigationPresentationRenderRecord`；`NavigationPresentationEndpoint` 先配对记录再提交结构请求，拒绝时撤回。节点／队列和 handle 共享内部 lifetime，lifetime 只通过 weak observer 通知 record。Router 不保存业务配置、View 或闭包。record 在回调期间保留配置，完成后解除引用。

内部页面接手点在生命周期 probe 的 `makeUIViewController`：控制器初始化同步调用 `NavigationModalMount.claim`，随后用真实 presenter／window 关联和关闭 completion 完成收尾。业务 builder、sheet 内容闭包求值和 `onAppear` 不作为接手或完成信号。只有从未挂载的同一 probe 真实销毁才能证明请求被丢弃；已挂载请求不能用 dismantle 或 Router 销毁提前完成。调用方无需也不能手动报告这些内部事件。

真实呈现测试从独立 SwiftPM test target 移到 `project.yml` 的 App-hosted `ChineseCalendarUITests`，通过 `TEST_HOST`／`BUNDLE_LOADER` 使用 App。全部 App 测试和 Core 的两个 physical host 文件共用 `NavigationTestWindowLease`，在前台 scene 上以 `UIWindow(windowScene:)` 创建串行测试窗口。没有 connected scene 的 runner 无法仅凭 `makeKeyAndVisible()`／`onAppear` 验证真实呈现；scheme MacroExpansion 也不会替代 App host 配置。纯 Core 状态测试仍留在 SwiftPM，实际手势与布局交互仍需单独验收。

来源或 store 变化立即撤销旧结果资格、取消本次请求或任务，动画资源等真实结束后释放。年份结果必须先获得当前模态 `dismiss()` 接受，再通过 session 一次消费及 store generation 校验。历史和 DEBUG 分栏使用完整容器的 `@State`，数据查询子树可重建，布局 owner 保持稳定。错误提示改为携带 `CalendarStoreFailure` 等结构化值，由配置本地化，不再保存 messageID。

删除 `CalendarNavigationSessionCleanup`、`presentationSessionIDs`、`releaseDismissedContexts()` 及其集中业务字典；不建立弱寻址表、节点扫描器或全局关闭回调替代。`retainedPresentationRoutes`、`retains(context)`、`alertRoutes` 已删除。节点、内部 ID、队列、等待／确认状态、Context 的内部 route／destination 和 `isActive`、手动生命周期通知不再公开；按内部 ID 的关闭、确认与 Context 查找也由库内处理。

页面通过所在层 Context 取得栈并执行导航，外部请求走 `router.submit`。全局下载错误可用 `router.presentAlert`，前台层由库内选择。未挂载 `navigationHost` 的呈现返回 `.rejected(.hostUnavailable)`，不再把仅构造 Router 的测试视为真实呈现。

方案与完整合同见 [Issue #165](../../Docs/Tasks/issue-165-presentation-ownership/000-plan.md)，实际证据与覆盖边界见[结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)。原[集中观察清理任务](../../Docs/Tasks/task-2026-10-22-presentation-session-cleanup/000-plan.md)保留历史证据，已被此设计替代。

## 每类业务 alert 使用自己的 Action

移除 `NavigationAlertRoute.Action`。路由继续是 Hashable 数据，每类提示可定义独立的 `Action: Hashable`；相同选项的通知也可以共用一个 Action。不要将所有子 Action 包装到另一个大枚举。

配置的 `alertContent(for:)` 与 `handleAlertAction(_:action:presentation:)` 合并为：

```swift
func alert(
    for route: AlertRoute,
    presentation: NavigationPresentationContext<Scope, Destination, AlertRoute>
) -> NavigationAlertDefinition?
```

在每个 route 分支中，通过 `NavigationAlertDefinition(content:onAction:)` 将 `NavigationAlertContent<具体Action>` 与接收相同 Action 的异步 handler 配对。泛型初始化完成后才擦除具体类型，按钮去重和 Action 捕获已在同一类型下完成。将其他 Action 的按钮或 handler 传入会编译失败。完整双 Action 示例见 [README](README.md#业务-alert)。

业务函数按 Action 拆分，不再接收大统一 Action 或用 route guard 过滤不可能的组合。提示内容由 route 的结构化值直接构建；需要操作本层时使用配置方法传入的 presentation，不能固定使用根 Context。definition 只存在于配置／展示层，不能写入 Router、节点或排队状态。

`NoNavigationAlert` 仍可作为不使用业务提示的 route，默认配置返回 nil。普通／取消按钮的构造和去重不变，框架确认仍独立。真实关闭后才调用 handler；异步完成前继续占用会话，重复／过期／失效回调不会再次执行业务。方案与证据见 [Issue #164](../../Docs/Tasks/issue-164-typed-alert-actions/000-plan.md)。

## Core 内部继续保留强类型身份

#166 将模态、确认和业务提示身份分别改为 `NavigationPresentationID`、`NavigationConfirmationID`、`NavigationAlertID`，系统适配器用不同 case 保留来源。#165 保留这种内部隔离，同时收回节点和身份查询；业务不再从节点取 ID 或直接批准／取消内部确认。

App 只保留有独立业务用途的稳定身份。旧 `YearPickerSessionID`、`DownloadPreviewSessionID`、`CalendarAlertMessageID` 和 `CalendarPresentationSessionID` 的集中查表用途已移除，不必为新的 owner 再创建一组替代 ID。普通 DEBUG Destination 的 UUID 仍由具体页面身份用途决定，不机械删除。

内部强类型迁移的历史依据见 [Issue #166](../../Docs/Tasks/issue-166-typed-navigation-ids/000-plan.md)；当前外部 API 按本文第一节迁移。

## 将命令的 Bool／Void 返回值迁移为结果枚举

本次直接迁移命令 API，不保留旧 Bool 包装。方法仍标记 `@discardableResult`，仅发起操作的调用可以继续忽略结果；读取结果的调用按下表更新。

| 原调用合同 | 当前合同与调用方式 |
| --- | --- |
| 栈修改返回 Bool，部分 Router 修改方法返回 Void | 返回 `NavigationMutationResult`：`.applied`、`.noChange(reason)`、`.rejected(reason)`；原 `if navigation.push(...)` 改为 `if navigation.push(...).isApplied` |
| `present`、`presentAlert` 返回 Bool／呈现结果 | 返回 `NavigationPresentationSubmission`；使用 `.result.isAccepted` 判断接受，保存 `.handle` 定点取消／关闭 |
| `dismiss` 返回 Bool | 返回 `NavigationPresentationResult`：`.applied`、`.queued`、`.noChange(reason)`、`.rejected(reason)`；判断接受使用 `.isAccepted` |
| `NavigationRequestResult.rejected` 没有原因 | 改为 `.rejected(NavigationRejectionReason)`，匹配时读取关联原因 |
| 业务直接批准／取消内部确认 ID | 移除业务调用，由统一宿主处理；业务通过 `confirmationContent(for:)` 提供文案 |
| 通过属性赋值，无法读取拒绝结果 | setter 转调对应命令；Binding 接法不变，需要结果时调用 `setPath`、`setSelectedStack` 等方法 |

`isApplied` 只接受 `.applied`，适用于成功修改导航数据后再同步业务状态。`isAccepted` 包括 `.applied` 和 `.queued`，适用于判断呈现／关闭请求是否被接受；不要用它作为完成通知。`.applied` 不代表界面动画结束，`.queued` 可能在所属层失效后丢弃，不保证最终执行。

正常无操作有独立原因：栈底 pop 为 `.noChange(.alreadyAtRoot)`，根层 dismiss 为 `.noChange(.notPresented)`，已结束的 handle 再次关闭为 `.noChange(.notPresented)`。不要把所有 `isApplied == false` 或 `isAccepted == false` 都当成失败。重复写入同一合法 path 或选中栈仍为 `.applied`，保留 App 先校验访问权限、再同步布局的用法。

例如，原先以 Bool 结果保护业务选择的代码应改为：

```swift
guard navigation.setRootDestination(destination).isApplied else { return }
selectedCategory = category
```

保存命令为函数值时，函数的返回类型也要同步修改；需要 `() -> Void` 的位置用闭包显式忽略结果。根请求的等待确认、等待 alert 和等待根模态关闭阶段保留，不能将它们归并为“成功完成”。

诊断统一使用 `NavigationCoreLog` 的 `navigation` category：非法栈／容器配置为 `notice`，其余命令结果为 `debug`。最终决策记录一次，转发不重复记录；查询及内部幂等回调不打日志。动态层／栈身份为 private，不输出业务 Destination；调用方通过结果枚举决策，无需解析日志。方案和本次验证入口见[导航操作结果与诊断](../../Docs/Tasks/task-2026-10-22-navigation-results/000-plan.md)。

## 分开栈操作与层级呈现

- 根 `rootContext` 改为 `rootPresentation`，类型为 `NavigationPresentationContext<Scope, Destination, AlertRoute>`。
- `NavigationContext<Scope, Destination>` 只负责本栈的根、path、push、pop。页面另外从环境读取 `NavigationPresentationContext` 来 present／dismiss，不能通过 navigation 转取 presentation。
- Router 和呈现相关类型增加 `AlertRoute` 泛型。业务提示遵循 `NavigationAlertRoute`，在配置边界为各类内容绑定独立 Action 与 handler；不使用业务提示时采用 `NoNavigationAlert`。
- `dismiss()` 关闭当前所在的模态及后代；根层调用返回 `.noChange(.notPresented)`。来源关闭本次请求使用保存的 handle，栈内返回使用 `pop()`。

栈宿主默认注入记录发起栈的 `NavigationPresentationContext`。同层多个实例共享状态，不能依靠对象是否相同判断是否属于同一层。Tab 公共控件使用层级入口；同时可交互的分栏可显式使用 `unscoped()` 或 `restrictsPresentationToSelectedStack: false`。

`presentation.route`／`destination` 和 `isActive` 已收回库内。业务不通过路由 nil 或有效性查询判断生命周期；是否允许修改看操作返回值，资源结束使用单次 `onFinish`。同 ID 的新层不会使旧 Context 重新有效。

三类 Context 缓存统一由每个 Router 独立持有的内部 `NavigationContextStore` 管理；公开的 `context(for:)`、`rootPresentation`、`scoped(to:)` 和 `unscoped()` 接法不变。模态从树中移除时入口立即失效，真实 dismiss 完成后统一清理缓存。Context 与访问闭包继续弱引用原运行时状态。

## 将页面配置集中到根宿主

| 旧接法 | 当前接法 |
| --- | --- |
| `navigationPresentations(context:destinationContent:)` | 根部一次 `navigationHost(context:configuration:)` |
| 每个 `NavigationScopeView` 传 `destinationContent` | 从所在导航树继承配置，使用 `NavigationScopeView(stack:presentation:)` |
| 业务自行创建 `NavigationPresentationNodeView` | 删除业务接入；节点递归宿主为 Core 内部实现 |
| 根、push 与模态分别使用 builder | `NavigationHostConfiguration.destination(for:)` 统一构建 |
| `NavigationConfiguredDestination` 转调 builder | 宿主直接调用配置，不增加包装 View |

递归呈现宿主由 Core 创建，业务 Tab 或多 Tab 模态不重复挂 `navigationHost`。独立导航树和独立 Preview 各自提供根配置。

原模态 builder 中用于全 App 的数据注入应移到根呈现宿主外。发起页面自己的 selection、ModelContext、回调仍按会话传递，不能用根页面固定上下文替代。

配置协议的 `presentationDidDismiss()` 已移除；删除实现及手动转调。当前资源回收使用提交处的 `onFinish`，配置只负责页面和提示构建。先前过渡方案中的保留路由投影和集中扫描清理也已删除，详见[发起方所有权迁移](#迁移到发起方所有权与单次结束通知)。

## 容器声明改由 Destination 提供

业务路由遵循 `NavigationDestination`，只通过 `providesNavigationContainer` 声明整层入口的承载方式：

| 当前值 | 行为 |
| --- | --- |
| `false`，默认 | Core 提供 `.primary` NavigationStack |
| `true` | 页面自行组织 TabView／NavigationSplitView 及其栈，Core 直接构建页面 |

旧宿主 `providesNavigationStack(for:)` 与 App 的 `usesPresentationNavigationStack` 中，`true` 表示 **Core 包栈**。新属性 `true` 表示 **页面提供容器**，不能照搬旧布尔值。

删除 Destination 的 `allowedNavigationEntries`、`navigationContainer` 及对应枚举；当前没有 `NavigationContainerKind` 或 root／栈根／push／模态入口白名单。普通 push 仍在当前栈构建页面，不自动创建新层或独立栈空间。同一层同一栈只挂一个宿主，不能在 Tab 栈中再次构建复用这些栈的完整 Tab 容器。

App 的主 Tab 入口由 `.root` 改名为 `.mainTabs`。页面读取当前层环境，关闭按钮根据 `isPresented` 和本栈 path 决定，不按页面路由推断运行时位置。

## 使用明确的栈身份与必填根

- Scope 从 `Hashable` 约束改为显式遵循 `NavigationScope`。给已有类型增加协议遵循即可；协议继承 `Hashable`，不要求 `CaseIterable` 或 `Codable`。
- 新接入使用 `NavigationStackID<Scope>`：默认栈为 `.primary`，命名栈为 `.scope(scope)`。旧代码若以 `Never` 作为 Scope，应改用显式遵循 `NavigationScope` 的业务类型；只有默认栈时可定义无成员的 `enum AppScope: NavigationScope {}`，需要命名栈时再增加成员。
- Router 初始化增加整个根层的 `rootDestination`。统一初始化器与 `present` 均使用 `initialStack`、以 StackID 为 key 的 `rootDestinations` 和 `paths`；基于 Scope 的根 Tab 便利入口仍存在。
- `NavigationPresentationRequest.sheet`／`.fullScreen` 及 Context 的 `present` 接受 `initialStack`、`rootDestinations` 和 `paths`。容器入口必须通过这些参数声明根；普通页面可继续省略。匹配请求枚举时，两个页面 case 各有四个关联值。原 Router 的 `presentSheet`／`presentFullScreen` 不再公开，页面改用来源 Context。
- 外部容器为要显示的各栈声明根，至少覆盖初始选中栈及所有带 path 的栈。push、写 path、切栈和获取 Context 都不隐式创建无根栈；需要动态增加根层命名栈时，先通过 Router 的 `.setRoot` 请求声明根，再获取 Context。
- 栈根必须是非可选 Destination。`setRootDestination`／`.setRoot` 不接受 nil；SplitView 的空详情使用明确的空态路由。换根同时清空 path，同一对象重复选择时由 App 保留原根和 path。
- `NavigationContext.rootDestination` 仍是可选查询，nil 表示未声明或已失效的 Context。Preview 的 root closure 只覆盖显示内容，不能绕过根声明。

TabView 绑定完整的 `presentation.selectedStack`，保留 `.primary` 与命名栈的区别。Router 的 `selectedScope`、`paths`／`rootDestinations` 等汇总投影不再公开；查询和操作根层或模态的具体栈都通过该层 Context。

## 移除完整导航树快照与恢复调用

删除 `NavigationSnapshot`、`NavigationLayerSnapshot`、`NavigationPresentationSnapshot`、`NavigationRouter.snapshot`／`restore` 及日历 App 的 `CalendarRouter.restorableSnapshot`／`restore`。移除相应编码、解码、业务可恢复性过滤和仅服务这些接口的 `Codable` 遵循；业务地址若另有编码用途，仍由该用途决定是否保留。

没有替代整树快照的公开接口。运行时查询使用所在层 Context 的 `rootDestination`、`path`、`selectedStack` 等现有 API；测试直接断言需要验证的状态。新建根层或模态继续使用 `rootDestination`／destination、`initialStack`、`rootDestinations`、`paths` 的正常初始化参数，内部完整校验后才建立状态，不经过恢复模型。

运行期间各 Tab 的路径、仍存续的父模态状态和 App 分栏选择行为保持。跨启动保存与恢复完整界面不在当前能力范围；Deep Link 仍通过业务地址解析和 Router 请求协调处理。原 #158 中“恢复成功后清理 Context”及恢复兼容测试随 #159 的能力删除而不再适用，关闭后的生命周期验证继续保留。

## 业务提示统一进入呈现队列

页面用 `presentation.present(.alert(route))` 提交业务提示，配置通过 `alert(for:presentation:)` 返回绑定内容与 handler 的 `NavigationAlertDefinition`。移除为同一业务流程另设的 `.alert`／`.confirmationDialog` 呈现状态。Core 的确认适配已改用真实 UIKit 关闭 completion，旧 SwiftUI `alert(item:content:)` 确认宿主不再使用。

| 旧按钮配置 | 当前配置 |
| --- | --- |
| 可以为空的按钮数组 | 必填 `firstButton`，其余放入 `additionalButtons` |
| 普通按钮中的 `.cancel` role | 独立的 `NavigationAlertCancelButton`，通过 `cancelButton` 传入 |
| 只有一个取消按钮 | `NavigationAlertContent(title:message:cancelButton:)` |

相同普通 Action 采用最后内容，保留首次位置；取消按钮独立于普通集合。显示顺序与点击动作映射使用同一份结果。

业务 alert 关闭后，框架等待异步按钮动作与排队呈现结束，再继续外部请求。按钮“确定”不自动批准外部导航；提交时的确认要求仍然保留。实际关闭由 Core 宿主推进，业务不能把状态清空或固定延时当作关闭完成。

Router 的 `deferredRequest`、`pendingConfirmation`、`requestWaitingForAlert` 是内部协调状态，业务不再读取这些投影。已批准请求和新待确认请求可以并存，取消后者不撤销前者。业务层不再另存一套关闭窗口、延迟请求或 presentation 树。

## 设计与验证记录

这些链接用于追溯决策及其当时的证据；当前 API 以源码和 README 为准，构建、自动测试与实际交互应分别查看。

| 主题 | 记录 |
| --- | --- |
| 发起方所有权与 API 收敛 | [#165 方案](../../Docs/Tasks/issue-165-presentation-ownership/000-plan.md)、[结果记录](../../Docs/Tasks/issue-165-presentation-ownership/001-result.md)，最终验收以结果证据为准 |
| 强类型操作结果与诊断 | [2026-10-22 方案](../../Docs/Tasks/task-2026-10-22-navigation-results/000-plan.md)，迁移旧 Bool／Void 命令合同 |
| 初始统一导航与作用域 | [#145 计划](../../Docs/Tasks/issue-145-unified-navigation/000-plan.md)、[独立环境 API](../../Docs/Tasks/issue-145-unified-navigation/009-separate-context-apis.md) |
| 业务 alert 与请求协调 | [统一提示](../../Docs/Tasks/issue-145-unified-navigation/011-unified-alerts.md)、[协调状态](../../Docs/Tasks/issue-145-unified-navigation/015-coordination-state.md) |
| 路由读取与 Context 有效性 | [层入口路由](../../Docs/Tasks/issue-145-unified-navigation/016-readable-context-route.md) |
| 根宿主配置与统一页面构建 | [#148 计划](../../Docs/Tasks/issue-148-navigation-host/000-plan.md)、[统一 builder](../../Docs/Tasks/issue-148-navigation-host/002-unified-destination-builder.md) |
| Destination 容器声明的早期方案 | [#152 计划](../../Docs/Tasks/issue-152-destination-containers/000-plan.md)，其中入口白名单与 Core 多栏预留声明已被后续方案替代 |
| 根层与模态采用相同结构 | [同构导航层](../../Docs/Tasks/task-2026-10-20-homogeneous-navigation-layers/000-plan.md) |
| 运行时导航边界与 Context 缓存生命周期 | [#159／#158 方案](../../Docs/Tasks/issue-159-navigation-runtime/000-plan.md)，替代历史快照恢复能力 |
| App 原生两栏／三栏组合 | [#146 计划](../../Docs/Tasks/issue-146-navigation-containers/000-plan.md)、[栈根路由化](../../Docs/Tasks/issue-146-navigation-containers/002-routed-stack-roots.md) |
| DEBUG 操作入口 | [Debug 操作记录](../../Docs/Tasks/issue-145-unified-navigation/007-debug-actions.md) |
