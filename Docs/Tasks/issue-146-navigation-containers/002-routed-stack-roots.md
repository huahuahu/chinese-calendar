# 栈根统一使用 Destination

- 日期：2026-10-21
- 状态：源码与自动测试已完成；实际交互待验证
- 关联：[原方案](000-plan.md)、[导航规范](../../Conventions/Navigation.md)

## 决策与范围

将原方案中 App root 闭包直接构建详情的方式调整为根 Destination：SplitView 仍由 App 声明，前栏分类和布局仍由 App 管理；详情根保存稳定路由，空选择使用明确的空态 Destination。对象 selection 从详情根投影，不再独立保存。SDK 不认识栏数。

每个已声明栈必须具有根 Destination，运行时 path 使用非可选数组。获取 Context 不再隐式创建无根栈；缺少声明的 Context 不可操作。容器必须显式提供选中栈及所有带路径栈的根。根切换清空 path，重复选择同一对象保持 path；受阻操作不得提前修改分类或布局。

快照省略空 path，缺失与显式空数组统一为空；不再保留是否曾记录路径这一实现细节。恢复拒绝无根栈，删除的栈使旧 Context 失效，保留的栈继续复用对象。根层和模态层采用相同规则。已有仅供 Preview 的根内容覆盖保持可用，但依赖的栈仍必须声明根路由。

## 验收

- 非可选栈根及 path；读取 Context 不改变快照。
- SplitView 空态、换根、清空、重复选择、继续 push 和分类保留策略。
- 缺失根配置拒绝；快照空路径归一化、恢复及旧 Context 失效。
- 模态关闭与确认门禁保持；不同 Tab、递归模态相互隔离。
- 原生 Xcode 测试、format/lint 和文案校验；实际交互单独记录，不以测试替代。

## 实际结果

已将栈根和 path 改为非可选状态；容器初始化、呈现和恢复均检查根声明，获取 Context 不创建无根栈。SplitView 使用 `.debugSplitEmpty` 和 `.debugSplitDetail` 描述详情根，由共享 destination builder 构建，选择从根路由投影。清空和换对象清除旧 path，重复选择保留 path；分类及布局仅在栈接受动作后更新。

新增／更新自动测试覆盖根与 path 恢复、缺根配置拒绝、空路径归一化、删除栈的旧 Context 失效、分栏选择与事务门禁，以及 Tab／模态隔离。2026-10-21 最终整合工作区通过原生 Xcode 全部 384 项测试，format、严格 lint、333 项文案校验及 diff 检查均通过。

本轮没有执行新的 Simulator 点击、宽窄切换或真机验证，不能将此前 root 闭包版本的交互记录视作本实现的验证。原“只修改本地文件”的授权阶段已结束，用户要求将当前全部改动统一提交新 PR；完整范围、API 兼容变化和源码／验证证据见[整合记录](../issue-145-unified-navigation/017-navigation-state-integration.md)。
