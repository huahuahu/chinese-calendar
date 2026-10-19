# 页面导航与模态呈现

适用于 App 运行时的页面 push、sheet、full-screen、业务 alert、嵌套 presentation 及页面级 popover。实现与 review 使用同一规范；框架 API 见 [NavigationCore](../../Sources/NavigationCore/README.md)。

## NAV-01 — 唯一的结构状态来源

页面导航使用 `CalendarRouter` 组合的 `NavigationCore` 状态。每个呈现层拥有独立栈集合和一个可选的直接呈现内容：页面模态或业务 alert。页面模态携带 sheet／fullScreen 展示方式及下一层状态；alert 只携带提示 ID 和业务路由，没有下一层或导航栈。根层与模态层遵循同一结构，同层多个 Tab 共享呈现状态、保留各自 path。sheet/fullScreen/alert 读取同一呈现枚举，不为同一流程并行维护局部呈现 Boolean、可选路由项或另一套 path。

单个栈的根身份与 path 由独立 `NavigationStackState` 保存，层只组合这些栈对象和呈现状态。层的 roots/paths 字典是值投影，不重复保存路径；批量替换和根快照恢复更新已有栈对象，避免页面持有的上下文脱离真实状态。

根据实际调用链判断是否是 App 页面。设置能打开的 DEBUG 下载演示属于本规则；文件位于 `PreviewSupport` 或用 `#if DEBUG` 包围不是豁免依据。

## NAV-02 — 结构、业务与数据的边界

Router 保存“去哪里”的页面身份和导航结构。业务层负责 destination、URL 解析、页面构建和上下文传递。日期选择、列表查询、下载进度、演示阶段、滚动和动画状态留在对应 feature／coordinator。

`NavigationCore` 只理解泛型 scope、destination、path 和 presentation；不得依赖日历类型、SwiftData 模型、数据查询或业务页面。业务会话可以通过 ID 关联呈现上下文，但不能成为第二套呈现状态源。

所有 `present` 接收强类型路由数据，由宿主映射为页面或提示文案。业务适配器不接收或保存待展示的 View。业务 alert 定义独立 `AlertRoute` 与关联的 `Action` 类型，业务层处理按钮动作和异步工作。Core 统一保存待确认请求、排队的呈现、已批准的延迟请求和系统关闭事务，业务层不再另设关闭窗口或复制 presentation 树。

## NAV-03 — 发起作用域与生命周期

每个呈现层注入 `CalendarPresentationContext`，负责本层 `present`、自身 `dismiss`、选中栈和离开确认，不提供 path／push／pop。根宿主使用 `rootPresentation`，不隐式代理当前选中 Tab 的栈操作。栈宿主从层级入口取得带发起栈身份的呈现入口并单独注入环境；这些入口共享同一层状态，不要求对象相同。

每个栈注入绑定本栈的 `CalendarNavigationContext`，根页及其 push 后代共享它。它只提供本栈身份、有效性、path、`push` 和 `pop`，不公开 presentation，也不转发 `present`、`dismiss` 或 `isPresented`。页面直接读取 `CalendarPresentationContext` 发起模态操作；需要业务协调时传递发起页面的呈现上下文，不能借 navigation 获取。带发起栈身份的呈现入口拒绝后台 Tab 的 present；TabView 附件等层级控件使用不绑定栈的呈现入口。

栈 context 只弱引用独立栈状态，依赖仅含 isActive/canMutate 判断的窄接口，不直接引用 Router、NavigationLayer 或呈现上下文。Router 在组合时通过弱捕获注入对象身份和事务检查；呈现 context 则弱引用原层及 Router，负责呈现生命周期。

普通模态使用 `.primary` 栈，多 Tab 模态使用 `.scope(...)` 命名栈并显式设置 `initialStack`。同名栈在不同层中互相隔离。模态关闭后，其栈与呈现 context 均失效，不能操作随后恢复的同 ID 新层；根栈 context 在根快照恢复时保持连接。

`dismiss()` 表示关闭当前所在的模态及其后代。根层的呈现 context 没有自身所在的模态，调用时返回 `false`；它们不能用此方法关闭自己展示的模态。栈内返回单独使用 `pop()`。跨 Tab、外部请求和整树管理使用根 Router。

需要回传结果的页面必须使用正确发起页的上下文。年份选择器继承该页面的 `CalendarSelection`、ModelContext 和年份选择回调，不能从根部借用另一个日历页的选择。

导航 owner 与宿主的生命周期要覆盖其呈现流程。store identity 改变时，应重建依赖新容器的页面、失效旧容器的呈现会话，并显式保留或完成正在协调的外部导航。下载详情持续读取 store coordinator 的进度，不将打开时的快照当作持续状态。

会话关闭或失效后不能继续回传结果；关闭完成后释放其上下文。不得依赖偶然的 View 重建来清理导航。

## NAV-04 — 系统 API 的合法使用

通用宿主负责实际展示。以下使用允许保留：

- `NavigationScopeView` 与 `navigationHost` 内部递归呈现宿主中的 `NavigationStack`、`.sheet`、`.fullScreenCover` 等，绑定对应 Router／presentation 状态。业务内容复用这些宿主。
- `NavigationLink(value:)` 使用项目 destination，写入 Router 绑定的 path，并由所在栈注册 destination。
- 仅提供导航栏、没有页面 push 的集中 Tab 根容器。新增 push 时，必须明确其 Router scope／path。
- 仅用于独立渲染的 `#Preview` 和测试容器。helper 被 App 调用时，按真实调用链重新判断。
- 组件展开等不需要阻塞外部导航的局部交互状态。
- Core 的统一 alert 宿主使用原生 `UIAlertController`，通过真实关闭 completion 串行处理业务提示与离开确认。业务页通过呈现环境提交 `.alert(route)`，不另挂 `.alert`／`.confirmationDialog` 形成第二套提示状态；旧 `alert(item:content:)` 确认宿主已移除。

不能仅凭搜索到某个 API 判违规；需要指出实际 owner、宿主、触发链和未同步的导航结构。

## NAV-05 — 关闭和外部导航协调

关闭动作应明确对应哪个 presentation。按钮关闭、下滑关闭和自动关闭都同步同一节点状态；关闭子详情不能误关父页面，进度消失不能关闭无关模态。

外部导航经过 Router 的请求协调：有模态时先向最前作用域提交离开确认，取消保持原树和路径；批准后关闭 presentation，等待根宿主报告 dismissal 完成，再应用目标。子节点的关闭通知不能冒充整棵根 presentation 已关闭。

当前已有业务 alert 时，保留原提示并保存最新外部请求及其确认要求；等 alert 实际关闭、按钮异步动作完成，再处理排队提示和外部请求。有页面模态时随后显示离开确认，只有根 alert 时直接导航。业务按钮不自动批准外部请求，不在已有 alert 上叠第二个 alert，也不用固定延时推测关闭完成。

后续业务提示按同层队列顺序处理；alert 按钮可以排入结果提示。若队列里是页面模态，等该页关闭后继续。关闭当前模态也须等活动 alert／业务动作完成，随后丢弃失效层的排队呈现。重复关闭回调不能重复执行业务动作。任何子模态仍在关闭时，不提前从父层展示离开确认。

提示与请求 ID 绑定，相同待确认请求去重，新请求替换提示时必须产生新 ID。旧确认不能批准新目标。已批准的导航可采用 latest-wins，但关闭动画期间收到的未批准链接仍需单独确认，不能复用上一次批准。没有模态的冷启动直接导航，重复完成通知应幂等。

`@Environment(\.dismiss)` 可在正确的呈现环境中使用；要沿调用链检查它关闭的是页面、栈中的一页还是窗口，以及框架绑定是否同步，不能只凭属性声明判违规。

## NAV-06 — 容器归属、例外与验证

每个导航栈由一个 `NavigationScopeView` 宿主提供容器，业务详情不得重复创建同一栈的 NavigationStack。自带多 Tab 容器的页面通过本层呈现 context 取得各 Tab 栈，并绑定本层 `selectedStack`；宿主配置的 `providesNavigationStack(for:)` 返回 false，避免重复包装。内部不再挂第二份呈现宿主，页面级子模态仍由该层唯一宿主管理。

App 根 View 通过 `navigationHost(context:configuration:)` 集中提供 `NavigationHostConfiguration`，统一承载根与递归节点的 sheet/full-screen/alert、context 注入和确认提示。各栈只声明身份与根页面，自动读取所在导航树的配置，并在自己的真实 NavigationStack 内注册 destination；不能只在 TabView 外层注册一次。

配置属于 View 宿主，不进入 Router 或两种操作 Context，不使用进程级注册。独立导航树可提供不同配置；同树的 Tab、模态及多 Tab 模态共享构建规则，保留各自状态与 Context。普通 push 与模态页面可以提供不同构建入口；页面的 selection、ModelContext 和回调仍按发起作用域传递，不能捕获根页固定业务上下文代替。

业务配置只提供页面、容器策略、提示文案及数据环境；`handleAlertAction` 处理业务动作，宿主等待它完成；`presentationDidDismiss` 仅用于业务上下文清理，不重复处理全局导航。独立 Preview 也提供根配置；已经属于导航树的多 Tab 模态不再挂第二个根宿主。

快照包含页面身份、导航结构及当前业务 alert 路由，不包含排队请求、执行中的动作和转场。App 必须检查页面与提示的可恢复性，临时回调、ModelContext、下载状态及演示／错误消息会话不能仅凭 ID 跨进程恢复；恢复不能与当前模态或确认／关闭／业务动作事务竞争。日历 App 当前拒绝恢复业务 alert。

新增例外需要记录具体调用链、独立作用域的用途、状态 owner 和验证方式，不能按目录一概放行。对导航改动验证打开、关闭、返回、再次打开、涉及的嵌套、deep link、Tab 隔离及上下文失效。源码、结构测试、构建、Preview 与实际交互分别记录，构建或 Preview 不代替 Simulator 交互。

本次迁移的方案与验收见 [Issue #145](../Tasks/issue-145-unified-navigation/000-plan.md)，呈现层与多栈分离见 [008](../Tasks/issue-145-unified-navigation/008-presentation-layers.md)，独立环境 API 见 [009](../Tasks/issue-145-unified-navigation/009-separate-context-apis.md)，独立栈状态与内部依赖分离见 [010](../Tasks/issue-145-unified-navigation/010-independent-stack-state.md)。

业务 alert 的统一呈现与导航排队见 [011](../Tasks/issue-145-unified-navigation/011-unified-alerts.md)。

根宿主配置的迁移与验收见 [Issue #148](../Tasks/issue-148-navigation-host/000-plan.md)。
