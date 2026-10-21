# Issue #146：App 原生分栏与详情栈组合方案

- 关联：[Issue #146](https://github.com/huahuahu/chinese-calendar/issues/146)、[同构导航层 #156](../task-2026-10-20-homogeneous-navigation-layers/000-plan.md)、[Destination 容器与层入口 #152](../issue-152-destination-containers/000-plan.md)、[统一页面构建方法 #148](../issue-148-navigation-host/002-unified-destination-builder.md)
- 状态：可执行；本文件记录方案，实际实现与验证由结果记录逐项说明
- 更新日期：2026-10-21
- 决策依据：2026-10-20 明确的 App 原生分栏组合边界，取代此前由 SDK 建立普通／两栏／三栏通用容器状态、容器 Context 和多栏快照的草案

## 背景、目标与范围

使用原生 `NavigationSplitView` 表达 App 的分类和对象选择，并复用 NavigationCore 已有详情栈、模态、alert 与外部请求协调。业务选择决定详情根内容，SDK 只管理详情 push path；避免把 App 列表联动和 SwiftUI 布局状态变成框架新的结构模型。

首轮范围为固定小数据的 DEBUG 普通／两栏／三栏入口、必要的最小 Core API 调整，以及对应测试、交互验证和文档。正式历史 Tab 的产品布局、数据查询和选择行为不在本轮改造范围。SDK 不新增通用容器 Context、列类型、多栏快照或 App selection／布局恢复承诺。

实现遵循[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)、[本地化规范](../../Conventions/Localization.md)与[导航规范](../../Conventions/Navigation.md)。任务记录及证据分类遵循[任务文档流程](../README.md)。

## 已核对的源码基线

调查起点为 `765fc18b2fb29b6e3f477d4822d73c55fd8eed7f`；以下是实现前源码事实，不作为本轮运行时验收证据：

- [NavigationScopeView](../../../Sources/NavigationCore/SwiftUI/NavigationScopeView.swift) 已提供显式 Context／presentation 与 root 闭包的组合入口，内部创建 NavigationStack、绑定该 Context 的 path，并从配置注册 push Destination。
- [NavigationLayerContent](../../../Sources/NavigationCore/SwiftUI/NavigationLayerContent.swift) 已根据 `providesNavigationContainer` 决定是否为入口包栈；自带容器入口直接由配置构建。
- [NavigationContext](../../../Sources/NavigationCore/Routing/NavigationContext.swift) 已通过独立栈状态和窄访问约束处理 path／push／pop。基线的 path setter 不返回是否接受，因此 App 不能据其返回值决定是否同步修改 selection。
- 基线的 `NavigationContainerKind` 含 `.stack` 与被拒绝的 `.twoColumn`／`.threeColumn` 预留值；预留值不是已实现的 SplitView 能力。该类型及 Destination 入口白名单已由后续 [#156 同构导航层](../task-2026-10-20-homogeneous-navigation-layers/001-result.md) 删除，不属于合并后的 API。
- [NavigationPresentationContext](../../../Sources/NavigationCore/Routing/NavigationPresentationContext.swift) 和 [NavigationRouter](../../../Sources/NavigationCore/Routing/NavigationRouter.swift) 已负责独立呈现层、业务 alert、请求确认与关闭协调。本轮继续复用这些入口。

旧任务的测试、构建和交互记录只能说明旧代码状态；本轮组合后的宽窄切换、系统返回及布局写回仍须验证。

## 方案与决策

### 1. App 组织原生容器，最后一栏复用现有栈

App 在 SDK 外声明两栏或三栏 `NavigationSplitView`。两栏前栏、三栏前两栏使用 App selection 驱动列表，不设置独立 push 栈。App 持有 `columnVisibility`、`preferredCompactColumn`，处理用户操作和系统折叠／返回造成的 Binding 写回。

最后一栏使用 `NavigationScopeView(context:presentation:root:)`。root 闭包根据 App selection 构建选中对象或空详情，根内容不进入 path；该宿主提供唯一 detail NavigationStack，通过已有 `navigationHost` 配置构建后续 Destination。普通栈接法继续保留。

每个详情栈只有一个 `NavigationContext`，根内容和 push 后代共享它。前栏需要控制详情时显式获得该 Context 或业务动作，不通过隐含环境查找目标栈。不同 Tab、独立导航树及模态层继续使用各自 Context；分栏的列不映射为互斥 Tab 的 `selectedStack`。

### 2. App 负责选择与详情根的联动

| 动作 | 选择和详情路径的预期 |
| --- | --- |
| 选择不同对象 | 清空详情 path，再更新对象 selection；新对象成为根内容 |
| 再次选择同一对象 | 保留 selection 和已有详情 path |
| 切换分类并保留详情 | 更新分类，保留已有对象及其详情 path；此策略由明确的业务动作表达 |
| 切换分类并清空详情 | 同时清空对象 selection 与详情 path |
| 清空对象选择 | 清空详情 path，展示空详情内容 |

App 在同一个同步业务动作中计算并应用这些选择，不用多个 `onChange` 相互回写。需要路径变更时先请求 SDK 接受，再修改 selection；被事务或 Context 生命周期拒绝时保持原业务状态。

### 3. SDK 只补最小路径操作能力

为 `NavigationContext` 保留 `setPath(_:) -> Bool`，沿用 Context 有效性与事务访问限制。合并 #156 后不恢复 Destination push 入口校验；Core 不根据页面位置拒绝 Destination。该方法只报告路径变更是否被接受，让 App 决定是否同步修改 selection；它不持有业务选择、不解释分类，也不新增跨栏事务或容器状态。系统 NavigationStack 仍通过 path Binding 使用同一份路径。

2026-10-20 的原方案只移除 `NavigationContainerKind.twoColumn`／`.threeColumn` 并保留 `.stack`；2026-10-21 合并 #156 时改为保留主干对整个 `NavigationContainerKind`、`NavigationDestinationEntry` 与入口白名单的删除。Destination 只声明 `providesNavigationContainer`：true 由 App 提供原生 NavigationSplitView 等容器，false 由 Core 提供当前层的 `.primary` NavigationStack，不新增 SDK 分栏 host 或列权限体系。

### 4. 容器模态与外部请求沿用既有协调

分栏容器作为 sheet／full-screen 入口时声明 `providesNavigationContainer == true`，跳过外层 NavigationStack，最后一栏自行使用 Core 详情栈。同层只有一个 presentation host，继承现有配置和本层 presentation，不再安装第二份 `navigationHost`。父模态与子模态的 path、Context 和选择会话保持独立。

业务 alert、嵌套 presentation、离开确认与外部请求继续使用当前真实 dismiss 协调。外部业务选择不在提交请求、等待确认、仅收到批准或等待关闭时提前修改：取消保持原 selection、path 和呈现状态；批准的请求实际应用时才同步修改外部 selection。已有 alert 先实际关闭并完成按钮动作，再处理后续提示和外部请求，不另设固定延时或本地确认状态。

### 5. DEBUG 验证与恢复边界

DEBUG 入口使用固定小数据，分别呈现普通、两栏、三栏组合，提供可观察的对象选择、分类保留／清空策略、清选择、push/pop、sheet／full-screen、嵌套模态和外部请求场景。实现入口属于 App 层，具体新增文件由实现确定；调试工具和数据不进入 NavigationCore。

SDK 快照继续覆盖其已有路由、path 和呈现结构，不保存 App selection、分类或布局 Binding，也不保证单独恢复详情 path 即可恢复整页。DEBUG 组合会话沿用不可恢复会话的策略；将来若产品需要分栏恢复，由 App 单独定义业务状态恢复与 path 校验。

## 实施顺序

1. 补充 `setPath` 的接受／拒绝反馈，沿用 #156 已移除入口白名单与容器枚举的边界；针对 Context 生命周期和事务拒绝补充测试，不以页面位置拒绝 Destination。
2. 在 App 层加入固定数据的 DEBUG 普通／两栏／三栏组合与集中选择动作，复用配置、详情栈及唯一呈现宿主。
3. 验证选择、Context 隔离和外部请求的状态规则，再执行窄／宽布局、系统返回、sheet／full-screen 和嵌套交互。
4. 执行对应测试、构建、格式／lint／文案检查，将实际代码状态、每项结果和缺口写入结果记录。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| MC-01 | 普通／两栏／三栏使用同一详情栈能力；原生 SplitView、前栏 selection 和布局 Binding 属于 App；前栏无 push 栈，最后一栏只有一个 NavigationScopeView；Core 无通用容器 Context、列类型或多栏快照 | 源码与宿主结构检查；DEBUG 入口构建 |
| MC-02 | 不同对象换根清 path、重复选择同对象保 path、分类切换可显式保留或清空详情、清选择同时清 path；`setPath` 被拒绝时 selection 保持原值 | 针对性状态测试；两栏／三栏交互 |
| MC-03 | 一个详情栈的根与 push 后代共享 Context，前栏显式操作该 Context；不同 Tab／模态栈互不影响，模态关闭后的旧 Context 不能修改重新打开的会话 | Context 与生命周期测试；隔离交互 |
| MC-04 | 窄／宽布局切换、系统返回、深 path 下的布局控制及 `columnVisibility`／`preferredCompactColumn` 系统写回保持选择与详情路径一致；记录实际平台行为和限制 | 指定 Simulator／系统版本的实际交互、截图或录屏；源码／构建不能代替 |
| MC-05 | 两栏／三栏作为 sheet 和 full-screen 打开时不被重复包栈，同层只有一个 presentation host；嵌套打开、返回、关闭、重新打开保留正确父子状态 | 宿主结构检查；sheet／full-screen 及嵌套交互 |
| MC-06 | 外部请求取消保原 selection／path／呈现；批准且真实关闭后实际应用时才修改选择；已有业务 alert、异步按钮动作、后续提示和外部请求串行，不提前叠加确认 | 既有请求协调测试及新增选择同步测试；取消／批准／alert 交互 |
| MC-07 | 正式日历、历史、设置 Tab 的栈、年份选择器、下载预览多 Tab、既有业务 alert 和 Deep Link 行为保持；正式历史 Tab 未改成多栏 | 相关既有测试；受影响业务流程回归交互；范围 diff 检查 |
| MC-08 | 相关测试、iOS App 构建、格式、lint 与本地化检查完成，结果分别记录；源码、自动化测试、Preview、Simulator 和真机的证据不互相代替 | MCP 构建／测试；项目格式与 lint 脚本；文案资源检查；按证据类型记录结果与未验证项 |
| MC-09 | README 与导航规范说明 App／SDK owner、selection 与 path 规则、容器模态和外部确认时序；明确快照不恢复 App selection／布局，并区分源码事实、实现计划和运行时证据 | 文档 diff、本地链接和九项验收 ID 检查；结果记录逐项对应 |

## 待验证事项与调整记录

- 原生 SplitView 在深 path、系统返回及程序修改布局 Binding 时的具体行为，须以本轮指定 Simulator 和系统版本交互为准。若平台行为阻止验收，记录复现与限制，不将新 SDK 容器抽象作为默认补救。
- 外部请求实际应用与 App selection 同步必须验证取消、批准、alert 队列和真实关闭时序；不得仅凭静态调用顺序标为通过。
- 2026-10-20：采用 App 原生分栏组合与最小 `setPath` 反馈，替代旧草案的 SDK 多栏状态、通用容器 Context、跨栏结构事务及多栏恢复模型。正式历史 Tab 保持首轮范围之外。
- 2026-10-21：合并 main 的 #156 同构导航层。根层与模态层复用 `NavigationLayer`、`NavigationLayerContent` 与 `NavigationLayerSnapshot`；普通根／模态使用 `.primary`，请求以 StackID 寻址，快照使用 `rootDestination + layer`。容器归属不变时恢复复用根栈，归属改变时重建栈并失效旧 Context。分栏仍由 App 组织，混合 Tab 从当前呈现层取得各栈；移除白名单不允许业务为同层同栈重复建立宿主。旧 255 项测试属于合并前快照，不能作为这次适配的通过证据；合并后构建、测试及文档检查由结果记录另行补充。
