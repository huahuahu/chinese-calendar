# 呈现 Context 的路由读取与有效性

> 本文保留该子任务的 43 项阶段验证及当时格式检查结果。当前统一 PR 已补跑全套回归并修复剩余格式问题，最终源码标识和验证结果见[整合记录](017-navigation-state-integration.md)。

- 日期：2026-10-21
- 依据：用户确认“页面路由始终可读，操作有效性单独判断”；[导航规范 NAV-03](../../Conventions/Navigation.md#nav-03--发起作用域与生命周期)
- 范围：仅调整呈现 Context 的 route／destination、导航层内容的渲染判断和相关回归；栈 Context 的 rootDestination 不在本轮范围内。

## 方案

`NavigationPresentationContext.route` 和 `destination` 改为非可选。Context 失效或 Router／Layer 释放后，仍可读取原层的路由信息；操作入口继续检查 `isActive` 和现有事务条件。`NavigationLayerContent` 以 `isActive` 判断是否渲染，直接使用非可选 destination。

层与其所有呈现 Context 共享一份轻量、可观察的路由记录，记录不引用 Router、Layer 或导航栈。根快照恢复更新同一记录，既有根 Context 和 scoped Context 立即读到新入口；释放后仍保留最后的值。恢复出的同 ID 模态拥有新记录，旧 Context 不连接新层。

## 验收与结果

已实现。新增 `NavigationLayerRouteState` 保存唯一的入口记录，Layer 和呈现 Context 共用它；宿主改为以 `isActive` 控制渲染。三个新增状态测试覆盖释放后的读取、同 ID 新层隔离及根恢复的观察更新；新增宿主测试通过 `ImageRenderer` 验证失效内容不调用页面 builder，并更新既有旧 Context 断言。

| 验证 | 结果 |
| --- | --- |
| 原生 Xcode MCP `RunSomeTests` | 5 个相关测试套件、38 个测试方法展开为 43 项；全部通过，0 failed／skipped／not run；包含 iOS 测试所需构建 |
| 本次 7 个 Swift 文件 `swiftformat --lint` | 通过，0 文件需格式化 |
| `./Scripts/lint.sh` | 286 文件，0 violations |
| `git diff --check` | 通过 |
| `./Scripts/format.sh --check` | 未通过；仅另一处已有改动 `NavigationPresentationHost.swift:14–18` 存在换行／缩进问题，本轮未修改该文件 |
| Simulator 手动交互、真机、Release、远端 CI | 本轮未运行；ImageRenderer 测试不等同于系统关闭动画的交互验证 |

验证于 2026-10-21 20:24（北京时间）使用 `ChineseCalendar.xcodeproj`、scheme `ChineseCalendar-iOS`、`chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0）执行。验证包含工作区原有的其他改动，不能当作这些改动的完整验收。测试后仅在 `NavigationLayer.swift` 补一行格式空白，并更新文档和证据；测试及最终源码 SHA-256、43 项测试明细见[验证记录](evidence/readable-context-route/validation.json)。
