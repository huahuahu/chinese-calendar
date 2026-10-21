# NavigationCore 运行时导航与 Context 生命周期：方案

- 关联：[Issue #159](https://github.com/huahuahu/chinese-calendar/issues/159)、[Issue #158](https://github.com/huahuahu/chinese-calendar/issues/158)
- 状态：可执行
- 更新日期：2026-10-22
- 实施起点：`9933ed8f`，工作区干净，与 `origin/main` 一致；GitHub 未发现其他未合并 PR。

## 背景、目标与范围

App 没有跨启动恢复完整导航树的产品需求。删除公开快照、编码和恢复体系，同时将三类 Context 的缓存与清理集中在每个 Router 独立持有的内部 Store。运行时栈、Tab、App 原生分栏、递归模态、Deep Link 和 alert 协调行为保持。

依据：[导航规范](../../Conventions/Navigation.md)、[通用规范](../../Conventions/Common.md)、[NavigationCore README](../../../Sources/NavigationCore/README.md)。历史设计记录保留其当时事实，并补充本次后续决策链接。前置设计见[同构导航层](../task-2026-10-20-homogeneous-navigation-layers/000-plan.md)、[导航状态整合](../issue-145-unified-navigation/017-navigation-state-integration.md)和[分栏详情栈根](../issue-146-navigation-containers/002-routed-stack-roots.md)。

## 方案与决策

1. 将根层与模态层的初始栈、根和 path 校验移入内部正常初始化代码，完整校验后再创建状态；Core 单栈必须使用 primary，选中栈与所有带路径栈必须有根。不引入另一套公开快照或通用恢复框架。
2. 删除 NavigationSnapshot、NavigationLayerSnapshot、NavigationPresentationSnapshot、Router.snapshot/restore 及 App 恢复适配。仅删除确认专用于恢复的协议约束、编码和辅助接口，保留 Deep Link 等独立功能。
3. 新增 MainActor 隔离的内部 NavigationContextStore，统一管理栈 Context、层 Context 和带 sourceStack 的呈现 Context。Router 持有 Store；Context 和访问闭包继续弱引用运行时状态。缓存命中核对原状态对象，失效调用不能覆盖有效缓存。
4. 保持 context(for:)、rootPresentation、scoped(to:)、unscoped() 等公开运行时 API。模态从树中移除时 Context 立即失效，真实 dismiss 完成后统一 removeInactiveContexts() 释放缓存持有关系。
5. 两 Issue 合并实施时，#158 关于恢复成功清理与恢复兼容测试的条目由 #159 删除恢复能力的决策替代，不保留不存在的触发点。保留同 ID 新状态不能复活旧 Context 的运行时测试，使用正常构建节点和内部最小测试设置。
6. 测试只为恢复编码服务的部分删除；借助 snapshot 比较状态的行为测试改用现有查询或最小局部投影，继续保留行为断言。App 分栏业务 selection 仍由 App 管理。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| NR-01 | 不再存在公开整树快照与恢复实现、业务恢复适配或恢复专属死代码 | 调用方扫描、源码审查 |
| NR-02 | 根与模态正常初始化同构、非法配置原子拒绝、根和 path 约束不变 | NavigationCore 初始化测试 |
| NR-03 | 三类缓存同源、重复获取身份稳定，Router/Tab/嵌套层隔离 | Context 回归测试 |
| NR-04 | push/pop、清空、切 Tab 保持有效 Context；后台 Tab 呈现限制保留 | 运行时行为测试 |
| NR-05 | 模态移除后立即失效；真实关闭后清理三类缓存；旧入口不影响同 ID 新状态 | 生命周期及弱引用测试 |
| NR-06 | 外部持有 Context 不保活 Router、层、栈；Store 随 Router 释放 | 弱引用测试 |
| NR-07 | App 分栏、Deep Link、确认取消、真实关闭后跳转及 alert 串行协调保持 | Core/App 导航回归与 iOS 测试 |
| NR-08 | 代表性 Tab、push/pop、嵌套模态、关闭并重开流程正确 | Simulator 交互并留证 |
| NR-09 | iOS 构建测试、format、lint、文案校验通过，文档一致 | 记录实际版本与检查结果 |

## 待定事项与后续调整

无待用户决策事项。未来若要恢复上次浏览的日期或历史对象，应另按具体产品需求评估少量业务标识，不在本次提供替代恢复功能。
