# Issue #152：Destination 容器声明与层入口

- 关联：[Issue #152](https://github.com/huahuahu/chinese-calendar/issues/152)、[多栏设计 #146](https://github.com/huahuahu/chinese-calendar/issues/146)、[根宿主方案](../issue-148-navigation-host/002-unified-destination-builder.md)
- 状态：已实施；验证结果与边界见 [001-result.md](001-result.md)
- 更新日期：2026-10-19

## 目标与范围

把 App 根页面、各 Tab 根页面和模态入口统一为 Destination，保留现有独立栈、唯一呈现宿主及真实 dismissal 后的导航协调。遵循 [通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md) 与[导航规范](../../Conventions/Navigation.md)。

## 方案与决策

1. NavigationCore 新增 `NavigationDestination` 协议。`providesNavigationContainer == true` 表示页面组织顶层容器，Core 不在外面包栈；这与旧 `providesNavigationStack == true` 的含义相反。另用类型化的 `NavigationContainerKind` 声明 Core 容器需求。当前仅支持 stack；两栏、三栏作为明确的未实现声明，拒绝进入状态，不降级成普通栈。
2. Destination 声明允许的入口，Core 校验根入口、栈根、模态与 push。自带顶层容器的页面不允许进入普通栈；路径赋值、导航请求和恢复同样校验，避免绕过 push 的约束。
3. `NavigationLayerRoute` 保存层入口并投影纯身份 `NavigationLayerID`。层是唯一来源，节点的 destination/id 与呈现 Context 的入口信息均从层投影。入口不随 Tab 或 path 变化。保留原层、原栈对象身份检查。
4. Router 创建时必须提供根 Destination。快照补入根入口；模态快照沿用已有 id/destination 字段，恢复时创建层入口，不额外保存一份副本。恢复先完整校验，再修改状态。临时业务会话仍不可恢复。
5. 根和模态共用 Core 的入口容器选择。宿主配置继续集中构建页面，不保存到 Router/Context。App 的 `.root`、日历／历史／设置根页，以及下载预览两 Tab 都有明确路由；各栈的 root/path 与层入口分开保存。
6. #146 后续负责 SplitView 状态、栏间原子联动、折叠和呈现权限。当前 selectedStack 权限仍只服务互斥 Tab；不将多栏当作多个互斥 Tab，也不宣称已支持多栏。

## 验收标准

| ID | 场景与预期 | 验证方式 |
| --- | --- | --- |
| DEST-01 | 根、Tab 根、普通页面集中通过 Destination 构建；普通 push 不重复包栈 | 源码、宿主测试、构建 |
| DEST-02 | 根 Tab 与下载预览多 Tab 各栈独立，一层仅一个呈现宿主 | 结构测试、Simulator |
| DEST-03 | Context 可读根／模态入口；push、切 Tab 不改变入口；相同页面重复呈现 ID 不同 | 状态测试 |
| DEST-04 | 关闭及同 UUID 恢复后旧 Context 仍失效；快照包含入口且拒绝无效结构及业务会话 | 编码往返、恢复及非法入口测试 |
| DEST-05 | alert、Deep Link、嵌套模态、push/pop、关闭重开保留行为 | 既有回归测试、Simulator |
| DEST-06 | README、规范、Preview 与示例迁移；说明 Bool 反转及多栏未实现边界 | 文档、构建、Preview |

分别记录结构测试、构建、Preview、Simulator 交互和未验证项，不复用旧任务证据冒充本轮验收。
