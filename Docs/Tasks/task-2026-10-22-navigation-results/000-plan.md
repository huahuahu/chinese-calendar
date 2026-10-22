# 导航操作结果与诊断：方案

- 状态：可执行，用户已授权实现
- 更新日期：2026-10-22
- 关联：[导航规范](../../Conventions/Navigation.md)、[通用规范](../../Conventions/Common.md)、[运行时状态与 Context 生命周期](../issue-159-navigation-runtime/000-plan.md)

## 背景、目标与范围

NavigationCore 的部分命令静默返回，另一些 Bool 同时表达上下文失效、事务阻挡或正常无操作，调用方和日志无法解释结果。现有 navigation logger 尚未接入操作。

为栈、呈现和根请求提供类型化结果与拒绝原因，在命令决策处统一记录诊断。同步迁移仓库调用方、测试及 API 文档。不改变导航结构、确认策略、队列顺序、Context 生命周期和真实关闭完成门槛，不新增依赖或最终完成通知系统。

## 方案与决策

- 栈修改返回 `NavigationMutationResult`：applied、noChange(reason)、rejected(reason)。重复设置合法路径仍为 applied，允许调用方在检查访问约束后同步业务状态。
- 呈现及关闭返回 `NavigationPresentationResult`：applied、queued、noChange(reason)、rejected(reason)。applied 只代表数据应用，queued 不保证最终执行。保留根请求 `NavigationRequestResult` 的阶段，rejected 增加原因。
- 使用 Swift 枚举原因，不使用数字或字符串错误码，不把正常等待和幂等回调改成异常。直接迁移当前仓库 API，保留 `@discardableResult`；调用方用 isApplied / isAccepted 或 switch 决策。
- 访问判断通过窄接口传递拒绝原因，Context 不因此依赖 Router。校验与原因共用同一判断来源；属性 setter 转调对应命令。
- 复用 `NavigationCoreLog` 与共享 logging 模块。公共命令在决策处记录一次；转发入口不重复记录，查询不产生日志。正常等待和无操作为 debug，非法栈／容器配置为 notice。动态层／栈身份按 private 处理，不输出业务 Destination。
- 内部回调继续幂等；过期 ID 不推进队列或重复业务动作。已排队请求仍依赖真实 dismiss 与业务动作完成。

## 验收标准

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| NR-01 | 栈操作区分应用、栈底无操作、上下文失效、事务阻挡，拒绝不修改状态 | 针对性测试 |
| NR-02 | 呈现区分应用、排队和具体拒绝，非法初始化无部分写入 | 针对性测试及现有初始化测试 |
| NR-03 | 根请求保留确认／延迟阶段，并返回结构拒绝原因 | 现有协调测试与新增断言 |
| NR-04 | 回调幂等、旧 Context 失效、队列与真实关闭边界保持 | 现有生命周期／alert 测试 |
| NR-05 | 日志集中输出操作与原因，查询和转发无重复，业务载荷不公开 | 源码检查、测试运行日志 |
| NR-06 | App 调用方仅在正确接受或应用状态同步业务；文档说明 API 变更 | 编译、调用方测试、文档检查 |

构建和测试使用共享 Xcode 工程／scheme／Simulator 上下文；完成 format 与 lint。此改动不调整 UI 布局，自动测试与构建证据不表述为 Simulator 手动交互或真机验证。
