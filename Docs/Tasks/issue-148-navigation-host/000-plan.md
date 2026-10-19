# Issue #148：根导航宿主配置方案

- 关联：[Issue #148](https://github.com/huahuahu/chinese-calendar/issues/148)、[导航规范](../../Conventions/Navigation.md)、[Issue #145](../issue-145-unified-navigation/000-plan.md)
- 状态：已实施并完成本轮验收，见 [001-result.md](001-result.md)
- 更新日期：2026-10-19

## 目标与范围

将各 Tab、普通模态、嵌套模态和多 Tab 模态重复传入的页面映射收敛到根 View 宿主。保留现有单栏导航结构、业务会话、alert 排队和实际关闭后执行外部导航的行为，不涉及 #146 的分栏设计。

## 方案与决策

1. 在 NavigationCore 的 SwiftUI 层新增 `NavigationHostConfiguration` 协议，提供普通栈页面、呈现页面及其 push 后代、容器策略、确认文案、业务 alert 和动作／清理入口。业务实现保存所需的 coordinator 引用，以方法构建页面；环境不保存裸 builder 闭包。
2. 根 `navigationHost(context:configuration:)` 将配置放入仅当前子树可见的泛型环境，并挂载唯一根呈现宿主。独立树可使用相同路由类型但不同配置；无进程级注册。配置缺失为接入错误，不能静默构建空页面。
3. `NavigationScopeView` 只需栈身份、所属呈现层与根内容；自行读取配置，在每个实际 `NavigationStack` 内注册 destination。保留显式 context 初始化入口。配置的 View 类型只在框架的页面构建边界擦除，不把 `AnyView` 放入 Router 或 Context。
4. 递归呈现宿主自动继承配置。普通模态仍提供 primary 栈；多 Tab 模态仍由内部各栈负责容器，不重复呈现宿主。
5. App 的配置实现集中原有两个构建入口及提示／回调。不捕获根页的 selection、ModelContext 或选年回调；继续由带 session ID 的年份选择流程查找发起页上下文。模态及其 push 页面保留现有 store 环境注入。
6. 更新三个根 Tab、下载演示的两个 Tab、独立 Preview 和 Core README 示例。遵循 [Common](../../Conventions/Common.md)、[SwiftUI](../../Conventions/SwiftUI.md) 与导航规范。

## 验收标准

| ID | 场景与预期 | 验证 |
| --- | --- | --- |
| HOST-01 | 根集中配置，各栈不再重复 builder，每个栈注册 destination | 源码、宿主测试、根 push / NavigationLink 交互 |
| HOST-02 | sheet、full-screen、嵌套与多 Tab 模态自动复用配置，无重复容器 | 宿主测试、Simulator 交互 |
| HOST-03 | 独立树／Tab／模态状态及 context 隔离，旧 context 失效 | 配置环境与现有结构测试、Tab 切换交互 |
| HOST-04 | selection、ModelContext 与结果回调沿用发起页 | 业务会话测试、年份选择交互 |
| HOST-05 | Router／Context 无页面构建职责，alert / Deep Link 协调保留 | 源码、现有协调测试、实际提示交互 |
| HOST-06 | App、Preview、README、规范采用新方式 | 构建、Preview、文档检查 |

结果分别记录自动检查、Preview 和实际交互；不把结构测试当作 SwiftUI destination 注册已运行的证明。
