# Issue #164：每类业务提示的独立 Action

- 关联：[Issue #164](https://github.com/huahuahu/chinese-calendar/issues/164)、[领域身份类型迁移](../issue-166-typed-navigation-ids/000-plan.md)
- 状态：可执行
- 日期：2026-10-23
- 依据：[导航规范](../../Conventions/Navigation.md)、[通用规范](../../Conventions/Common.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)

## 背景与范围

`NavigationAlertRoute.Action` 把同一树的业务提示绑定到一个 Action，造成清理、普通通知和 DEBUG 导航选项混合，handler 还需防御无效的 route/action 配对。本次解除该约束，在宿主配置边界将具体内容与同类型异步 handler 配对后擦除类型。Router 和队列继续只保存 route、身份及协调状态，不保存 View 或业务闭包。

本 PR 基于 Issue #166 的分支，分别提交两个 Issue；不把身份迁移和 Action 改造混为一个 PR。队列算法、最终导航完成通知、提示文案及导航结果语义不在本次调整范围。

## 接口与实现决策

- `NavigationAlertRoute` 仅要求 Hashable，移除 Action 关联类型；`NoNavigationAlert` 保留不可构造的默认用途。
- 保留 `NavigationAlertContent<Action>` 与普通／取消按钮的泛型和去重规则。
- 新增 `NavigationAlertDefinition`：泛型初始化器同时接收 `NavigationAlertContent<Action>` 和 `@MainActor (Action) async -> Void`。在该边界将已排序按钮的具体 Action 捕获为无参数异步动作，无 Any、AnyHashable 或运行时类型配对。
- 配置改为 `alert(for:presentation:) -> NavigationAlertDefinition?`，替代分别提供 content 与 handler。配置依 route 构建不同 Action 的 definition，并使用当前层 Context。
- 业务与框架确认复用系统宿主，身份继续由 `NavigationSystemAlertID` 区分。系统按钮只触发关闭；真实 UIKit dismissal completion 后先取得一次处理权，再 await 业务动作，最后释放会话和推进队列。旧、重复及失效 Context 回调不能取得处理权。
- App 将清理确认、通用通知、DEBUG 导航分别定义独立 Action；处理函数完整 switch 自己的选项，不保留统一大 Action 或 route/action guard。原文案和 messageID 清理行为保持。
- 为生产转换路径增加直接测试入口，验证类型擦除后按钮顺序、角色、取消和异步生命周期；不为测试改写 UIKit 关闭时序。

## 验收标准

| ID | 要求 | 验证方式 |
| --- | --- | --- |
| ACT-01 | 同一树支持至少两种独立 Action，handler 完整处理自己选项 | 源码、配置集成测试和 Simulator 点击 |
| ACT-02 | 异类按钮和 handler 不能接入对应 content | 真实 iOS 模块正向控制与独立编译失败样例 |
| ACT-03 | App 清理、结果、下载失败、DEBUG 提示全部迁移且行为保持 | App 测试、调用链检查、Simulator |
| ACT-04 | 内容／动作对应、取消、去重、异步门槛、旧／重复和失效回调正确 | 针对性自动测试，无固定延时猜测完成 |
| ACT-05 | 既有 alert、确认、排队、生命周期回归通过 | 原生 Xcode App/test build、RunAllTests、format、strict lint |
| ACT-06 | 两种 Action 的实际按钮行为、串行队列与离开确认正确 | 指定 Simulator 的真实点击、截图／层级／日志证据 |
| ACT-07 | 新配置方式可迁移，保留职责边界 | README、API 注释、MIGRATION、结果记录 |

## 交互验证计划

从现有设置和 DEBUG 导航入口复用真实提示流程：普通通知与导航选择体现两种 Action；清理流程验证取消和结果提示；现有连续 alert 入口验证顺序；在模态内请求外部导航验证确认、取消及继续。记录实际点击和可观察结果，测试／构建不能代替 ACT-06。若现有入口不足，先检查调用路径，以最小 DEBUG 入口补齐可复现行为，不改变生产业务流程。
