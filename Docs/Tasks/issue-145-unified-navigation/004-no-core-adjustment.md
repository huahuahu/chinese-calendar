# Issue #145：保持 NavigationCore 不变的范围修订

- 日期：2026-10-07
- 来源：用户在首轮实现后要求「可以不动 NavigationCore 这个 package 吗？」。
- 历史范围记录：此阶段曾优先于 [初版计划](000-plan.md)。用户随后明确授权复用 Core 宿主；其中“业务自行递归呈现、Core 宿主与 README 零修改”的部分已由 [005](005-reuse-core-host.md) 替代。Router／节点状态不变的边界继续保留。

## 实际边界

`Sources/NavigationCore` 与 `Sources/NavigationCoreTests` 全部恢复为基线 `88e3b74ae7bab044389a9a471346e16f9880bd1c`；包含 README，不只恢复 Swift 源文件。没有新增依赖或修改 Package.swift。导航规范入口保留在 AGENTS、Docs 索引、SwiftUI convention 及中英文 review skill，按这次范围约束取消模块 README 的修改。

业务页面仍通过 coordinator／`CalendarRouter.presentSheet`、`presentFullScreen` 发起展示，随后调用 Core 原有 API。`CalendarNavigationHost` 与 `CalendarPresentationNodeView` 是 ChineseCalendarUI 的集中呈现适配器，保留必要的 SwiftUI 系统修饰符；业务内容页面不再自建模态状态。

## 从 Core 移回业务层的能力

| 能力 | 当前实现与状态归属 |
| --- | --- |
| 查找和精确关闭节点 | `CalendarRouter.presentations` 递归读取原 Core 节点；`dismissPresentation(id:)` 调用相应节点或根的既有关闭能力，没有复制树 |
| 根按钮／下滑／自动关闭期间的新请求 | 根宿主绑定 `CalendarRouter.sheet/fullScreen`；setter 记录系统关闭窗口。只有 Core 未接管关闭时，业务适配器暂存这一窗口内的最新请求，在根 onDismiss 后调用 Core.submit |
| 深链接主动关闭模态、连续深链接 | 沿用原 Core.submit/deferredRequest/applyDeferredRequestIfReady；不在业务层再保存相同请求 |
| 关闭完成、重复打开 | `CalendarRouter.rootPresentationDidDismiss` 清理业务关闭窗口或通知 Core；关闭期间 present API 不创建新节点 |
| 演示自带 Tab 容器、嵌套详情清理 | 业务 `CalendarPresentationNodeView` 按 destination 决定栈归属，递归绑定 Core 原节点，并把子关闭通知用于清理业务会话 |

原 Core 的通用 `NavigationPresentationNodeView` 仍完整保留，其默认每节点一个 NavigationStack 的语义没有改变。App 的业务宿主负责本次特殊容器组合，不向公共框架加入日历需求。

## 验证边界

将原来新增于 CoreTests 的三项行为验证移到 `CalendarPresentationRoutingTests.swift`，验证新的实际适配边界；保留原 Core 测试。全量重新运行，宿主迁移后重新做关键 Simulator 交互与受控容器切换。旧版截图和日志继续保留但明确为首轮证据，当前版本使用 `evidence/no-core/` 的源码清单、测试和交互记录。
