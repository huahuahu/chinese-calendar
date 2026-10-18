# Issue #145：导航规范与 review 入口案例核对

2026-10-07，随 006 方案更新，按 [NAV-01–NAV-06](../../Conventions/Navigation.md) 对代表性片段做人工规则核对；不是一次多 Agent 产品 review，不宣称证明所有未来 review 都不会误报。中英文 review skill 均增加同一规范读取条件和“追踪调用链、先查允许场景”的取证要求，技能结构校验通过。

| 代表性片段／调用链 | 预期判定与本次核对 | 依据 |
| --- | --- | --- |
| App 的年份按钮设置局部 `isYearPickerPresented`，其 `.sheet` 不写 `CalendarRouter.navigation`（本任务迁移前片段） | 应指出：实际日历入口可达，Router 不感知该页面，外部请求的 dismissal 协调不覆盖它 | NAV-01／05；不是只凭 `.sheet` 名称 |
| 设置按钮经局部 Boolean 打开 `FullStoreDownloadPreview`（迁移前片段） | 应指出：设置存在 App 运行时调用链，DEBUG 和 PreviewSupport 目录不构成例外 | NAV-01 |
| `CalendarNavigationHost` 的 `.navigationPresentations(context: rootContext, ...)` | 不报告违规：结构状态与完成通知均来自统一 Router | NAV-04／05 |
| `CalendarPresentedDestinationView` 仅构建内容，由 Core 宿主提供 NavigationStack 与子 sheet/fullScreen | 不报告违规：Core 宿主绑定节点 path/子节点，业务层仅提供容器策略与页面环境 | NAV-02／04／06 |
| `CalendarHistoryHomeView` → `NavigationLink(value: .dynasty(...))` → `NavigationScopeView` → history context.path 与 destination builder | 不报告违规：值写入 Router path 且注册业务 destination | NAV-04；完整调用链而非单看 NavigationLink |
| 日格文件尾部 `#Preview { NavigationStack { ... } }`、仅被 Preview 调用的月条 helper | 不报告违规：只为独立渲染提供容器；同时核对调用方，不按文件名批量豁免 | NAV-04 |
| 设置的 `isConfirmingClear` + confirmationDialog | 不报告违规：局部确认交互，不构成新页面 | NAV-04 |
| 业务 presentation 宿主在当前呈现环境取 `dismiss`，按钮调用，SwiftUI 写回节点绑定 | 不报告违规：关闭作用域正确；不能把所有 `Environment(\.dismiss)` 视作问题 | NAV-05 |
| 演示内两个 NavigationStack，外层节点不再包装栈，详情仍是节点子 sheet | 不报告违规：两套 Tab 根容器有实际布局用途，页面模态状态仍统一 | NAV-04／06 |

人工核对重点：如果缺少路径绑定或调用方证据，review 应记录待核实点；不能把搜索结果直接升级为已确认缺陷。规则正文只维护在 Navigation.md，skill 中不复制第二套要求。
