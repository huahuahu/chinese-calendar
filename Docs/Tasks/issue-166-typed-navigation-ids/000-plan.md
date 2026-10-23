# Issue #166：领域身份类型隔离方案

- 关联：[Issue #166](https://github.com/huahuahu/chinese-calendar/issues/166)
- 状态：可执行；本记录在实现期间按 Issue 已确定的方案补录
- 日期：2026-10-22
- 依据：[导航规范](../../Conventions/Navigation.md)、[通用规范](../../Conventions/Common.md)、[导航操作结果](../task-2026-10-22-navigation-results/000-plan.md)

## 背景、目标与范围

模态、导航确认、业务 alert 和 App 临时会话此前都使用 UUID，编译器无法发现不同领域身份被误传。保留 UUID 的生成方式，通过独立值类型把每个身份限制在所属领域，不改变导航结果、日志、请求去重或关闭时序。

本次引入 `NavigationPresentationID`、`NavigationConfirmationID`、`NavigationAlertID`、`YearPickerSessionID`、`DownloadPreviewSessionID` 和 `CalendarAlertMessageID`。前三种属于 NavigationCore，后三种留在 ChineseCalendarUI。DEBUG 普通页面的 UUID 身份不属于这六个领域，继续保持原有定义。

## 方案与决策

- 使用独立 `nonisolated` 小值类型，遵循 Hashable，具备 Sendable 值语义，UUID 存储保持私有；不使用 UUID typealias 或通用 ID registry。
- Core 对外提供生成新身份的 `init()`，测试所需的同值初始化保持 internal，不公开拆出 UUID 或跨类型转换 API。
- 模态节点、层路由和 `NavigationLayerID.presentation` 共用 `NavigationPresentationID`；确认、alert、生命周期回调、队列与集合贯穿各自类型。请求继续按内容去重，不增加请求 ID。
- 系统提示宿主使用 `NavigationSystemAlertID.business(NavigationAlertID)` / `.confirmation(NavigationConfirmationID)`，替代 UUID 加来源 Boolean。即使底层 UUID 相同，两种提示也不能匹配对方的回调。
- App 的路由关联值、字典键、View 输入和清理逻辑同步迁移。聚合观察使用带类别的 `CalendarPresentationSessionID`，不降级为 `Set<UUID>`。
- 保留对象身份检查；同一类型的相同 ID 不代表新旧 Context 共享对象。旧回调仍不得推进新会话。
- 不增加依赖、持久化或恢复协议，不改变现有业务文案和用户交互。

## 验收标准

| ID | 预期行为 | 验证方式 |
| --- | --- | --- |
| ID-01 | 跨领域比较、API 或路由误传不能编译 | 真实 iOS 构建模块上的正向控制及独立负向 typecheck，失败样例不加入正常 target |
| ID-02 | 同类型同值相等，集合去重和字典查询正确 | Core / App 值语义测试 |
| ID-03 | Core API、节点、队列和回调全部迁移，无绕过转换 | 源码审查和 iOS 编译 |
| ID-04 | 共享宿主保留类别，业务／确认、旧／重复回调相互隔离 | alert 生命周期与同底层值回归测试 |
| ID-05 | 三种 App 会话及聚合登记均保留类别 | 路由、字典、会话清理和聚合登记测试 |
| ID-06 | 确认去重、latest-wins、排队、真实关闭、失效 Context 和同 ID 新对象行为不变 | 现有导航与 App 回归测试 |
| ID-07 | API、README、MIGRATION 对齐，构建测试和格式检查通过 | Xcode Simulator build/test、独立编译检查、format、strict lint；结果区分交互证据 |

## 验证边界

本任务的主要可观察变化发生在编译期，保留的运行时行为由既有和新增测试覆盖。构建和自动测试不代表真实 Simulator 点击验证；结果记录分别标明。独立 Action 类型和相应交互验收由后续 Issue #164 处理。
