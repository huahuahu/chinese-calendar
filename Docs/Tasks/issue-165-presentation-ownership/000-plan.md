# Issue #165：发起方所有权与导航公开接口收敛

- 关联：[Issue #165](https://github.com/huahuahu/chinese-calendar/issues/165)
- 状态：设计已实施，实现已提交，本地验证结果已归档；逐项验收、覆盖边界及 PR 交付状态统一见 [001-result.md](001-result.md)
- 日期：2026-10-23 至 2026-10-24
- 实施前基线：`224b13aa`（包含 #169 的独立 alert Action 与 store 替换修复）；此基线仅用于追溯实施前状态，验证快照在结果记录中单独登记
- 依据：[领域语言](../../../CONTEXT.md)、[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[导航规范](../../Conventions/Navigation.md)
- 替代关系：本设计替代[原集中观察清理方案](../task-2026-10-22-presentation-session-cleanup/000-plan.md)。旧记录保留历史实现及证据；集中清理链随本次迁移移除，新合同的验收状态独立记录，不沿用旧测试结果。

## 目标与边界

用户确认的原则是：谁发起业务呈现，谁拥有这次流程的资源；导航库在本次流程真正结束时通知发起方，由发起方清理。业务不需要查看导航树来推算释放时机。

本次完成以下工作：

1. 删除 App 的集中会话字典及观察导航状态的清理链，明确每项状态的业务 owner。
2. 给每次已接受的呈现提供一次结束通知，并支持发起方准确取消或关闭自己的请求。
3. 将导航节点、队列、关闭事务及内部身份收回 NavigationCore；对外保留命令、结果和 UI 确实需要的局部绑定。
4. 继续由业务方构建 View 和传递 Binding、对象及动作；复用既有 `destination(for:)`，保持统一的物理呈现宿主。

不新增 App 会话注册表、弱寻址字典、业务状态仓库、导航状态扫描器或全局业务关闭回调。不将 Session、ModelContext、View 或业务闭包放入 Destination。现有 alert Action 类型设计、日志及导航结果枚举的含义保持；每次请求的取消能力是本次封装所需的窄扩展。

## 实施前基线与待解决问题

- `CalendarHomeCoordinator` 用 `yearPickerSessions` 持有 selection、ModelContext 和选年闭包。`CalendarYearPickerDestinationView` 只收到 sessionID，再回查字典。字典同时参与重复打开检查。
- `downloadPreviewSessions`、`historyStates`、`debugSplitStates`、`alertMessages` 共用 `releaseDismissedContexts()`；根 modifier 观察 `retainedPresentationRoutes`、`alertRoutes` 和业务登记。
- 当时只有整树共享的 `NavigationHostConfiguration`；`destination(for:)` 不接收发起方上下文。实际 sheet 在层宿主，发起页面局部的环境注入不会自动向上到达这个宿主。
- Router、PresentationContext 仍公开节点、等待请求、关闭状态等查询；App 通过遍历节点定位关闭目标，也存在按内部 ID 关闭和手动报告关闭完成的包装。
- Core 已保留 `dismissingPresentation`、队列和真实关闭事务。它们有必要继续存在于库内。`NavigationContextStore` 本身已是 internal，无需让 App 接管。

以上描述实施前基线。迁移必须同时接通“来源资源到业务 builder”和“请求结束到来源 owner”两条路径；不能只删除字典或增加回调参数。

## 资源归属

| 资源 | owner 与共享范围 | 创建、失效与释放 | 数据和结果传递 |
| --- | --- | --- | --- |
| 日历 selection、年份过渡状态及选年动作 | 每个日历页面自己的稳定 feature | 随对应日历 feature 创建和结束；关闭 picker 后继续保留日历本身的状态 | Header 和 picker 引用同一个 feature；选年仍执行原有边界月份、滚动及过渡逻辑 |
| 本次 picker 的临时资源与请求句柄 | 发起日历 feature 的一个可选字段 | 点击时准备；拒绝立即回滚；已接受请求在结束回调清空；store 变更立即撤销旧请求的结果资格 | 发起方的本次配置直接引用这次资源，picker 获得正确 selection、ModelContext 和动作；不按 ID 查表 |
| DEBUG 下载演示状态 | 设置入口所属 feature 的本次演示流程 | 打开时创建，整个演示结束后释放 | 两个 Tab、附件、push 与嵌套详情共享完整演示 feature，子详情关闭不结束演示 |
| 正式下载详情的请求控制 | 覆盖下载流程的稳定业务 owner | 创建详情请求时记录句柄；进度消失时关闭该请求；结束时清空 | 进度继续读取 store coordinator 的实时状态；owner 不放在随进度消失而销毁的附件 View 内 |
| 历史与 DEBUG 分栏布局状态 | 对应完整分栏容器的稳定 feature | 容器首次创建时建立，正常重绘、Tab 切换及子页覆盖期间保留，容器结束后释放 | 业务通过现有详情栈 Context 操作；布局 owner 放在数据 identity 重建边界之外 |
| alert 临时文案 | 本次业务提示的值数据 | 构造提示时确定，提示结束后随请求销毁 | 优先用结构化错误类别及必要标量参数替代 messageID；业务配置映射本地化文案，维持现有独立 Action |

ModelContext、selection 等可能同时被来源页面使用。结束回调只撤销本次流程的引用和任务；不得把来源页面仍需要的对象一并清空。

## 最小呈现接口

公开接口使用 `NavigationPresentationSubmission`，组合现有结果与可选 handle；复用 `NavigationHostConfiguration`，不增加第二套构建协议。以下摘取年份 feature 的提交与回滚形状，结束时序遵循后文的单次请求合同。

```swift
guard let session = beginYearPicker() else { return }
let submission = presentation.present(
    .sheet(.yearPicker),
    configuration: configuration(session),
    onFinish: { [weak self, weak session] in
        guard let session else { return }
        self?.finishYearPicker(session: session)
    }
)
if submission.result.isAccepted {
    if yearPickerSession === session {
        yearPickerHandle = submission.handle
    } else {
        submission.handle?.dismiss()
    }
} else {
    finishYearPicker(session: session)
}
```

- `configuration` 可省略，省略时继承当前宿主配置；只有确实依赖发起页面资源的流程提供本次配置。
- `onFinish` 是绑定单次请求的 `@MainActor () -> Void`，不加入根配置协议，不需要公开结束阶段、节点列表或清理原因枚举。
- 提交回执确定为 `NavigationPresentationSubmission` 值类型，公开 `result: NavigationPresentationResult` 和 `handle: NavigationPresentationHandle?`。不增加结果状态体系；接受时返回本次 handle，拒绝时不返回 handle。
- handle 只提供 `dismiss()`：未展示则取消本次请求，已展示则发起正常关闭，已结束则幂等无操作。内部保存不可见的本次身份并弱引用操作目标，不公开 ID、node、status 或查询树的能力。释放 handle 本身不等于请求取消。
- 来源 Context 的 `dismiss()` 关闭的是来源所在模态；它不能代替本次新请求的 handle。子页面自己的 Context 又要实际构建后才出现，无法负责排队期间的取消。
- 页面内部关闭仍可使用环境中的 `presentation.dismiss()`。发起方处理进度消失、store 替换等事件时使用保存的 handle，不遍历 destination 寻找页面。
- 来源只保存本次资源和 handle，不另存呈现 Boolean 或导航队列。重复打开用该业务流程已有的可选资源字段防止重复发起，所有结束路径必须清空该字段。

示意中的 `finishYearPicker(session:)` 必须核对仍是同一次资源，避免旧结束通知清空新流程。配置、结束闭包可以在呈现期间延长来源 feature 或本次资源的寿命；handle 不反向强持宿主和这些闭包，防止形成环。

本次资源本身不保存强捕获其 owner 的结果闭包，避免 `feature → session → feature` 的循环。结果动作由配置在构建时连接到稳定 feature，或使用弱结果接收者；关闭完成后解除这些按次连接。

## 保留一个业务 builder，补齐按次配置传递

继续使用既有 `NavigationHostConfiguration.destination(for:)`。不新增 `modalDestination(for:)`、按页面类型区分的构建协议或业务页的第二个 `.sheet`。

完整传递路径为：

```text
发起页面的 feature 持有本次资源
    → 创建引用本次资源的业务配置
    → SwiftUI 宿主的呈现入口接收：结构请求 + 配置 + onFinish
        → Router 接收结构请求，负责接受、排队和关闭
        → View 宿主保留与这一次请求直接配对的配置
            → 原 destination(for:) 构建页面并传入 Binding / 对象 / 动作
            → 请求终止时调用 onFinish，解除本次配置和闭包引用
```

实现要求：

1. 在 `NavigationCore/SwiftUI` 内提供窄的宿主桥接，借现有呈现 Context 定位本层宿主。实现采用 `NavigationPresentationEndpoint`，具体配对与生命周期见后文的实施决策；Context 本身不保存配置。
2. Router 和 Destination 不保存配置或业务依赖。内部的结构请求与 View 侧的一次渲染记录直接配对；Router 只发出其正常终止信号。
3. View 侧记录仅容纳这次构建配置及结束回调，生命周期严格受这次请求约束。不得提供按业务 ID 注册、任意读取对象或长期缓存的接口，不得复制 Router 的队列排序和关闭决策。
4. 先完成配对，再提交请求，保证接受后立即取消或在同一轮 SwiftUI 更新前取消也能结束记录；拒绝则当次撤销记录。
5. 模态激活时，将本次配置传给既有递归宿主。该模态的栈根、push 页面和普通子模态继续复用同一构建方法；子流程有自己的依赖时才提供自己的配置，结束后不修改父流程配置。
6. 本次配置引用具体 session，不能只动态读取 `owner.currentSession`，以免旧视图读到后来创建的资源。App 的共享 store 环境继续使用现有根注入。
7. 关闭期间保持本次渲染资源，防止 `context.isActive` 变 false 时立即撤掉页面导致空白；停止接受命令与继续保留退出画面需要在 Core 内部分开处理。

这条宿主桥接是本计划最需要先验证的技术点。第一阶段必须展示具体的配对存储和引用图；若实现退化为另一张长期业务注册表、将配置塞进 Router，或需要新增一套物理模态宿主，则不符合本方案，应先修订该接入设计，不能带着缺口继续全量迁移。

## 实施时确定的接线决策

以下记录实施时采用的结构；构建、测试与交互证据集中维护在结果记录中。

| 责任 | 当前接线 |
| --- | --- |
| 公开提交 | `NavigationPresentationCommands` 提供 `present`／`presentAlert`，返回 Submission；无活动宿主时拒绝 `.hostUnavailable` |
| 按次配置 | `NavigationPresentationHost` 通过 `@State` 持有 endpoint；endpoint 在提交前创建 render record，保存本次配置及结束闭包，拒绝时撤回 |
| 结构与结束信号 | Router 节点／队列保存结构和内部 `NavigationPresentationLifetime`；lifetime 对 record observer 为 weak，不保存业务配置或闭包 |
| 定点结束 | `NavigationPresentationHandle` 强持本次 lifetime、弱持 Router，只提供 `dismiss()`；释放 handle 不取消请求 |
| 渲染资源 | `NavigationPresentationNodeView` 使用本次 record 的配置递归构建；record 结束时解除登记并取走回调，配置保留到回调返回 |
| 物理关闭 | 复用既有 SwiftUI sheet／fullScreen 与 UIKit alert；页面 probe 在 `makeUIViewController` 创建时同步向 `NavigationModalMount` 认领本次 lifetime；已挂载页面依靠真实 dismiss／transition completion 收尾，未增加业务层第二套宿主 |
| 年份 | `CalendarYearFeature` 由日历页面持有，拥有 selection、ModelContext、过渡及本次 session；coordinator 只构造引用该 feature/session 的配置，不保存会话字典 |
| 下载 | `FullStoreDownloadPreviewFeature` 由设置入口持有；演示配置直接共享本次 state。正式详情由应用级 `CalendarDownloadDetailsFeature` 持有自己的 handle |
| 分栏 | `CalendarHistoryContainer`／`CalendarDebugSplitContainer` 以 `@State` 持有布局 state；移开整层的 store identity 重建边界，历史查询子树保留自己的数据隔离 |
| 提示 | `CalendarStoreFailure` 保存错误类别和必要标量；route 直接携带该值，配置调用本地化映射，保留每类独立 Action |
| 外部调用与测试 | App 删除集中字典、清理 modifier、节点 typealias 和手动完成包装；App 集成测试用普通 import，和 Core 物理呈现测试一起进入 App-hosted `ChineseCalendarUITests`，以真实前台 scene、builder 与弱引用探针验证 |

当前引用关系：

```text
来源 feature → 本次 session
来源 feature → handle → lifetime
                   └── weak Router
SwiftUI host → endpoint → render record → 具体配置 → 来源 feature / session
Router 的节点与队列 → lifetime ── weak observer ─→ render record
```

endpoint 弱引用所属 layer，record 弱引用 endpoint；lifetime 的 observer 和 handle 的 Router 引用都不反向保活业务配置。这里的记录是一次呈现的渲染责任，不提供业务 ID 注册／查找，不承担 Router 队列排序。真实宿主结束时负责切断按次配置与回调引用；不能用此引用图代替实际释放证据。

实施偏差：业务迁移和测试接线与 Core 生命周期实现并行推进，没有严格按最初的分阶段顺序完成。验收仍以真实接手、关闭和释放证据为依据，不能因为字典已删除或 API 已收回就判定端到端合同成立。

## 2026-10-23 实施调整：接手边界与测试宿主

页面呈现的内部接手点已确定为 `NavigationModalLifecycle.makeUIViewController` 创建 `NavigationModalLifecycleController` 的同步初始化；初始化调用 `NavigationModalMount.claim`，核对本次请求尚未结束后记录 controller 身份并 `claimHost()`。业务 builder 求值、sheet 内容闭包求值、`onAppear` 和 `.applied` 都不作为接手证据，也不推迟到异步任务才认领。这样，页面在入场期间移除来源宿主时，关闭责任已经交给物理生命周期协调对象。

认领表示宿主承担结束责任，不代表页面已显示完成。probe 通过真实 parent／presenter 和 window 关联记录是否曾挂载；已挂载的页面必须等真实关闭 completion 或未取消的 transition completion。只有同一个 probe 从未观察到物理挂载且随后真实销毁时，才可把它视为未进入窗口的请求已被丢弃；`dismantleUIViewController` 只补记最后关联，不直接完成请求。已完成请求拒绝晚到 probe，物理关闭后仍等待后代 alert 动作的记录也不能被重新认领。

宿主 teardown 在需要时保留 render record，直到请求及后代动作真正结束。Router 销毁前保留 lifetime 的父子完成依赖，不能让祖先的物理关闭提前完成后代异步动作。原生 alert 关闭 completion 清除本次 `currentAlert` 及同 ID 的 `desiredAlert`；动作 Task 独立保留 definition／render lifetime 到 handler 返回，避免已经消费的 presenter 内容继续保活业务配置。

首轮真实宿主诊断发现，独立 SwiftPM runner 没有 connected scene；Core 与直接 `UIHostingController.present(UIViewController)` 的 UIKit 对照均停留在 `isBeingPresented == true`、被呈现控制器 `view.window == nil`，而 Core 已 `hostClaimed == true`。因此仅 `UIWindow(frame:)`、`makeKeyAndVisible()` 与 `onAppear` 不足以提供真实 UIKit 呈现环境；scheme 的 MacroExpansion 也不等于配置了 App host。

当前由 `project.yml` 声明 App-hosted `ChineseCalendarUITests`，通过 `TEST_HOST`／`BUNDLE_LOADER` 使用 `ChineseCalendar-iOS`。目标包含全部 App 测试和 Core 的 `NavigationPhysicalHostTests.swift`／`NavigationPhysicalHostSupport.swift`；SwiftPM 的 `NavigationCoreTests` 排除这两个文件，保留不依赖窗口的内部状态测试。两个窗口 helper 共用 test-only `NavigationTestWindowLease`，串行获取前台 `UIWindowScene`，使用 `UIWindow(windowScene:)`，缺少真实 scene 则明确失败；挂载错误、取消等待和关闭均有对应释放路径。等待轮询真实条件，不以固定延时、skip 或手动完成代替系统证据。

这次调整补足验证环境和真实接手边界，没有改变下列验收标准。App-hosted 自动测试与下滑撤销、Tab／宽窄切换等实际 Simulator 交互分别提供证据，统一见 [001-result.md](001-result.md)。

## 每次请求的结束合同

`onFinish` 只属于已接受的请求，恰好调用一次。拒绝请求撤回临时记录且不投递回调，业务根据同步结果调用同一个清理方法回滚，避免同步回调和返回结果双重释放。

| 场景 | 结束时机与要求 |
| --- | --- |
| `.rejected` / 未接受的 `.noChange` | 不调用 onFinish；撤回临时渲染记录，来源同步释放本次准备的资源 |
| 已接受且排队 | 保留来源资源；从队列被取消或因祖先退出被丢弃时立即结束，不等待不存在的 UI 回调 |
| 已应用但系统尚未接手展示 | 取消后直接终止，不能无条件进入等待 `onDismiss` 的状态；覆盖同一轮 UI 更新前 present 后取消 |
| 系统已接手展示，包括尚在入场动画 | 走宿主真实取消／关闭流程，在确认本次 UI 结束后通知 |
| 已展示后按钮或手势关闭 | 关闭请求和 Binding 写回不等于完成；真实系统关闭完成后才调用 onFinish |
| 手势取消、被子模态遮盖、Tab 切换 | 不结束，也不释放会话 |
| 祖先或 Deep Link 关闭整棵子树 | 已显示后代等覆盖它们的真实关闭完成；未显示后代终止排队；每次请求只通知一次，不依赖已经失效的子 Context 再收到回调 |
| 旧通知晚到、重复完成 | 内部校验具体请求身份和一次性终止标记；不能结束后来打开的请求 |
| 业务 alert | 实际关闭后继续等待按钮异步 handler 返回，再结束；未显示就取消的提示不执行按钮 handler |
| 导航宿主真正销毁或整树退出 | 库的宿主拆除路径启动终止；未接手请求直接取消，已接手请求由仍存活的内部关闭协调对象完成收尾后通知。普通 onDisappear 或 dismantle 不直接等于系统关闭完成 |
| Router 销毁 | 无物理呈现的请求终止；正在显示或关闭的请求由宿主继续完成收尾。不能用 Router 或业务对象的 deinit 证明动画已结束；进程终止不承诺执行回调 |

内部先使旧请求无法再次操作、取走并清空一次性结束责任、结束对应事务，再按既有规则推进已批准导航和已有队列，最后同步投递 onFinish。投递期间用局部引用保留旧配置所需资源，回调返回后解除引用。回调重入产生的新命令在已稳定的状态上处理，不得抢在此前请求之前执行，不另设一套回调重入队列。同一批祖先整体结束的回调按后代先、祖先后执行；来源清理核对本次资源，不能误清新状态。

Core 继续负责真实关闭、Context 失效、alert 异步动作、队列推进和延迟导航；其内部生命周期机制不会随公开查询一起删除。`onFinish` 不提供“关闭刚开始”的通知，也不承诺任意业务后台任务在此刻已被取消。来源主动取消或 store 失效时可立即取消自己的任务；结束回调负责最终取消和释放。

年份结果必须通过当前模态的受控关闭命令获准后，再经本地 session 一次消费与 store generation 检查提交；关闭中或已失效的 Context 会拒绝命令。这样不用公开 `isActive` 来轮询，也不需要增加另一套业务失效广播 API。

## 公开 API 收敛清单

“不访问内部状态”指不能得到导航树、节点、队列、事务和内部身份；App 自己声明的栈身份、path、选中 Tab 等是刻意提供的 UI 契约，继续经过受控读写。

| 对外能力 | 保留范围 |
| --- | --- |
| `NavigationRouter` | 初始化配置、`rootPresentation`、协调外部导航的 `submit`；下载错误这类全局事件仍可调用 `presentAlert`，前台层的选择在库内部完成 |
| `NavigationContext` | App 声明的栈 id、rootDestination、path，以及受校验的 setRootDestination / setPath / push / pop |
| `NavigationPresentationContext` | 当前层 selectedStack 绑定、context(for: stack)、scoped / unscoped、present / alert / dismiss，以及 UI 关闭按钮所需的 isPresented |
| 单次请求 handle | 仅定点取消／关闭本次请求的 dismiss 命令 |
| SwiftUI 接入与业务定义 | NavigationRootView、NavigationScopeView、navigationHost、既有 Configuration、提示内容／Action 定义、路由和值请求、展示方式及现有操作结果 |

具体收回以下接口：

- 删除 `retainedPresentationRoutes`、`retains(context)`、`alertRoutes` 及只为它们存在的辅助代码。
- Router 的 `presentations`、`presentedNode`、`sheet`、`fullScreen`、`frontmostPresentationNode`、`hasActivePresentation`、`hasActiveAlert`、等待／确认／延迟请求等改 internal。
- PresentationContext 的节点、presentedContent、alert、confirmation、内部 layer id / route / destination，以及用于生命周期查询的 isActive 改 internal；NavigationContext 的同类有效性查询在业务缓存迁移后收回。
- 按内部 ID 取 Context、关闭节点、批准／取消确认、手动报告 presentationDidDismiss、applyDeferredRequestIfReady 等均仅由库内使用。
- `NavigationPresentationNode`、`NavigationPresentation`、`NavigationAlertNode`、层路由／层 ID、提示和确认节点及内部 ID、`NavigationPresentationNodeView` 在退出公开签名后改 internal。
- 内部身份继续保持 #166 的强类型隔离，只改变可见性，不改回裸 UUID 或跨领域复用身份。
- Router 的整树路径汇总、根栈直接 setter 及重复的 presentSheet / presentFullScreen / dismissSheet / dismissFullScreen 便利入口从公开面移除。根 UI 使用对应 Context；外部跳转使用 submit。
- `NavigationLayer`、`NavigationStackState`、协调状态和 Context Store 已在内部，继续保留其导航职责。源码文件间需要协作的成员使用 internal，单文件辅助逻辑使用 private。

App 不保留 node typealias、转发节点查询或手动关闭完成的包装。不为测试增加 public / SPI 后门。Core 内部测试可使用 `@testable`；App 集成与公开 API 验证使用普通 `import NavigationCore`，通过实际行为、命令结果、UI 与释放探针验收。

## 业务迁移步骤

1. **年份选择纵向迁移。** 在 `LunarYearDestinationView` 的稳定 feature 内统一 selection、年份过渡状态及选年动作；`YearMonthHeader` 保留 UI 组合和绑定，不再将捕获旧 View 状态的方法长期保存。将 `.yearPicker(sessionID:)` 的查表流程改为本次配置直接提供资源；如果 sessionID 不再有业务身份用途则一并移除。
2. **来源与呈现分别持有正确引用。** 模态配置可在退出期间延长来源 feature 的寿命；来源退出导致请求失效时，必须终止对应请求，不能靠 owner deinit 触发另一端结束而形成相互等待。父子流程按实际请求分别清理。
3. **store 替换。** 每个资源 owner 在业务 store 更新时撤销旧 generation、取消自己的任务及 handle；这份订阅覆盖排队和退出期，不只挂在会被数据 `.id` 移除的来源子 View 上。构建和结果提交也核对 generation。沿用 #169 对旧容器／数据库文件的存活保护，保持根宿主和外部导航事务，不全量重建 Router。
4. **下载演示和正式详情。** 演示 state 由入口 feature 的当前演示字段持有，本次配置供演示所有 Tab 和子详情使用；正式下载的稳定业务 owner 记录详情 handle，进度消失只关闭自己的请求。移除按 sessionID 查找父节点与详情状态的路径。
5. **历史和 DEBUG 分栏。** 用稳定容器 feature 持有布局状态；root / modal 中相同栈名的实例仍独立。将数据查询子树与布局 owner 的重建范围分开，保留 Tab 切换、push 和宽窄切换期间的布局。
6. **提示文案。** 将已有错误映射拆成结构化值和本地化映射，alert route 仅携带恢复文案需要的值，不保存 Error 对象、ModelContext 或闭包；删除 message 字典和清理动作参数，按[本地化规范](../../Conventions/Localization.md)保留现有文案，保持 #164 的不同 Action 和真实关闭后异步执行规则。无需为纯值提示建立会话对象。
7. **删除集中链和冗余包装。** 删除 `CalendarNavigationSessionCleanup`、`presentationSessionIDs`、`releaseDismissedContexts()` 以及五类业务缓存；移除 App 的 `rootPresentationDidDismiss`、frontmost fallback、关闭事务预检和节点扫描。页面来源显式传 Context，Preview 传自己的根 Context。

## 实施顺序与交付

| 阶段 | 工作与完成条件 |
| --- | --- |
| 1. 最小端到端验证 | 用现有业务 builder 完成两个独立来源 → 本次配置 → 统一宿主 → 结束回调的真实宿主链；验证 queued / 同轮取消、关闭动画、祖先退出及引用环。记录配置桥接的具体实现，确认没有业务注册表。此阶段失败则先修订接入设计 |
| 2. Core 生命周期与命令 | 完成按请求的一次性终止、宿主接手边界、私有身份核对、handle 和重入顺序；保持队列、alert 与 Deep Link 行为 |
| 3. 迁移业务 owner | 先迁移年份选择，再迁移下载、分栏和提示；每条实际调用链都有 owner、共享范围和结束路径，再删除对应字典 |
| 4. 封装与文档 | 将清单中的内部类型和查询收回，迁移 App 调用和测试；更新 README、MIGRATION、NAV-02/03/05/06 及原任务替代标记 |
| 5. 回归验收 | 完成下表自动验证和实际交互；形成 `001-result.md`，分别记录通过、失败、未验证及实际代码状态 |

用户授权范围包含实施与创建 PR。实际代码快照、验收结果及远程交付状态统一记入 [001-result.md](001-result.md)；本节保留原定实施顺序及完成条件。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| OWN-01 | 两个日历来源及嵌套 picker 使用各自 selection、ModelContext、结果接收方；保留选年滚动与动画 | 实际 builder 集成测试、Simulator 选年和重开 |
| OWN-02 | App 无集中业务字典、弱寻址替代、导航扫描清理和全局关闭回调 | 调用链检查、依赖搜索 |
| OWN-03 | 拒绝只同步回滚；已接受请求恰好结束一次；queued / 同轮取消不残留资源和等待状态 | Core 测试、真实宿主集成、weak probe |
| OWN-04 | 按钮、下滑和 fullScreen 关闭完成前保留渲染资源，完成后解除引用；交互撤销和被覆盖不释放 | 真实系统宿主测试及 Simulator；不能用手动调用完成入口代替交互证据 |
| OWN-05 | 祖先退出、Deep Link 取消／批准、整树销毁覆盖活动及排队后代；父子结束顺序正确 | Core 回归、宿主 teardown 测试、实际嵌套交互 |
| OWN-06 | 旧完成通知、旧 handle、重复点击和结束回调重入不操作新请求，不绕过外部导航顺序 | 针对性身份／重入测试 |
| OWN-07 | store 替换立即阻止旧业务操作；旧容器退出安全，待处理外部导航继续完成 | 沿用并补充 #169 store 集成测试、实际清空／替换交互 |
| OWN-08 | 下载演示跨 Tab / 子详情共享；子详情退出保留父状态；正式进度消失只取消自己的详情 | 业务测试、Simulator 演示与进度路径 |
| OWN-09 | 历史／DEBUG 分栏在普通重绘、Tab、push、宽窄切换保持状态，容器结束可释放 | 容器集成测试、Simulator |
| OWN-10 | alert 独立 Action、串行队列、异步按钮、错误文案和 Deep Link 确认保持正确 | 既有 alert 回归及关键交互 |
| API-01 | 正常 App 用普通 import 可完成 Tab、SplitView、push、呈现、取消和结果处理 | 外部使用样例正向编译、完整 App 构建 |
| API-02 | 普通 import 无法访问 node、队列、事务、内部 ID、保留查询或伪造系统完成 | 与正向控制配对的独立负向编译样例，不只依赖文本搜索 |
| VAL-01 | Core / App 相关回归、iOS build、format 和 strict lint 通过 | 按 Xcode 工作流配置 MCP，运行针对性测试后完整回归；记录真实结果 |

释放证据需要测试真实引用：来源 feature、本次 session、配置捕获与可取消任务。强制清空字典、直接调用业务 cleanup 或仅统计条目数量不能作为生命周期验收。保留原 Core 关闭/队列测试的有效断言，公开投影断言迁为内部生命周期行为和弱引用证据。

宿主退出测试覆盖等待、已显示、关闭中和 alert 异步 handler 挂起四个时点；暂停 handler 时，onFinish 和后续导航都必须继续等待。关闭正式下载详情不取消 store coordinator 的真实下载任务。

构建和测试遵循 [Xcode 工作流](../../agent-workflows.md#xcode-project-context)，先读取 `.xcodebuildmcp/config.yaml`，优先 native Xcode MCP。构建、自动测试、Simulator 交互及远程交付分别在 [001-result.md](001-result.md) 登记证据。

## 设计要求与验证边界

- endpoint／record／weak observer 的配对以实际 builder、queued／同轮取消和释放探针证明完整生命周期，检查资源环及漏通知。
- 接手边界位于 probe 的同步 make／claim；用同轮取消、入场时移除宿主、未挂载 probe 销毁和真实关闭回归核实，不以 builder 求值或源码接线代替运行证据。
- 根宿主真正拆除与临时消失的区分；终止通知在 MainActor 上一次性执行，且不依赖仍存活的业务 View。
- 完整容器 feature 与 store 数据 identity 的重建边界需要真实 UI 证据；测试局部持有的 state 不能替代生产 View 的 `@State` 生命周期。

这些要求用于检查发起方所有权、单次结束通知和内部状态封装；各项当前状态及未覆盖边界见结果记录，不在方案中重复维护进度。
