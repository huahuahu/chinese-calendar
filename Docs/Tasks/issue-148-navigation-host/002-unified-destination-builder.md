# 统一页面构建方法

- 日期：2026-10-19
- 关联：[原方案](000-plan.md)、[原结果](001-result.md)
- 状态：实现完成；自动验证通过，部分 Simulator 交互受工具故障阻碍
- 代码状态：从 `b33df5e9ec83b64f74a93404ce1646aac2da1c52` 实施；提交前同步到 `e4768959073b3103e75d7dbebafe233534341c54`，包含已合并的系统 fullScreenCover 简化；验收源码指纹见 [automatic-checks.json](evidence/unified-builder/automatic-checks.json)

## 调整依据与方案

用户确认：导航栈只管理 path、根页面和 destination 到 View 的映射；不根据是否位于模态选择 builder，也不需要额外的 `NavigationConfiguredDestination` View。

1. 删除 `presentedDestination(for:)` 和包装 View；栈与模态入口直接调用同一个 `page(for:)` 方法，类型擦除仅保留在该方法内。
2. App 的 SwiftData 上下文、数据完整度和 store coordinator 在覆盖根呈现宿主的环境中统一提供；页面映射不再为模态补注入数据。
3. 每个模态仍在入口获得自己的 presentation；每个栈保留自己的 navigation 和带发起栈身份的 presentation。页面映射不承担这些职责。
4. 保持根呈现宿主稳定；数据 identity 改变时只重建数据页面，年份选择会话继续使用发起页上下文并在 store 切换时失效。
5. 同步 Core README 与导航规范；原方案中的双 builder 决策由本记录替代，保留历史验收边界。

## 验收

- 源码中没有双 builder 和包装 View；根栈与模态调用同一方法。
- 宿主配置、页面环境继承、模态与栈隔离、store 环境更新有针对性自动测试。
- App 与测试构建通过；Swift format、严格 lint 和 diff 检查通过。
- Simulator 验证根 push、模态内 push/pop、嵌套模态、年份选择与下载详情；不把自动测试当成实际交互证据。

## 结果

`NavigationScopeView` 从环境读取宿主配置，在 `.navigationDestination` 中直接调用 `configuration.page(for: destination)`。模态入口也调用该方法；`NavigationConfiguredDestination`、`presentedDestination(for:)` 及日历侧的 `CalendarPresentedDestinationView` 已删除。类型擦除集中在方法内，没有新增 View 包装。

`ChineseCalendarRootView` 在根呈现宿主外统一提供当前 `ModelContext` 和数据完整度；`CalendarNavigationHost` 提供 store coordinator。环境 modifier 保持结构稳定，store identity 改变只重建依赖数据的页面。每个模态和栈继续在各自入口取得 presentation/navigation，年份选择会话保留发起页的 selection、ModelContext 和回调。Router、状态树和操作 Context 未修改。

验证使用 `ChineseCalendar.xcodeproj` / `ChineseCalendar-iOS`，共享配置指定的 `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0。

| 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| 删除双 builder 和包装 View | 已验证 | Swift 源码无旧类型／方法引用，栈和模态入口共用页面方法 |
| 环境继承与作用域隔离 | 已验证 | 配置渲染、模态共享环境和现有 navigation/presentation 测试通过；根与模态分别保留自己的 presentation |
| App 与测试构建 | 已验证 | 原生 Xcode MCP `BuildProject(buildForTesting: true)` 成功 |
| 全量测试 | 已验证 | 初轮原生 `RunAllTests` 为 289 通过；同步到 `e4768959` 后再次完整执行，仍为 289 通过，0 失败、0 跳过、0 未运行，包含补强后的查询断言 |
| 补强后的 SwiftData 查询测试 | 已验证 | 初轮全量测试后仅为 3 项数据环境测试加入 `@Query` 断言；原生 `RunSomeTests` 复验 3/3 通过，最终全量再次通过。含从空容器切到有数据容器、查询更新且 presentation 身份不变 |
| 格式与严格 lint | 已验证 | 同步后最终 Swift 源码 format 为 0/265 文件需修改；lint 为 254 文件、0 violations；本地化校验和 `git diff --check` 通过 |
| 根 push/back、模态根与内部 push | 已验证 | 西汉根详情与返回、sheet 真实数据、sheet 内 13 位皇帝列表均实际操作通过 |
| 年份选择和回传 | 已验证 | 2026 → 2025 后自动关闭并显示乙巳年；重开仍选中 2025，关闭正常 |
| 模态内 pop、嵌套 full-screen 和下载详情 | 未验证 | 原生会话两次丢失，第三方启动交互超时，重抓仍为主屏；未完成后续路径 |
| 实际 store 替换 | 未验证 | 本轮只以自动测试验证容器切换；Simulator 已安装完整日期数据，未清空或重新下载 |

测试摘要与源码指纹见 [automatic-checks.json](evidence/unified-builder/automatic-checks.json)，当前实现的交互步骤和关键截图见 [runtime-report.md](evidence/unified-builder/runtime-report.md)。交互发生在同步 `e4768959` 前，之后只重新执行自动检查；本轮证据不复用首次迁移的交互结果。没有重跑 Preview 或真机验证，也未启动专项代码审查。

运行日志在切换历史／设置 Tab 时出现 `Update NavigationRequestObserver tried to update multiple times per frame`。警告后历史导航仍完成；尚未确认触发条件及其是否与此次改动或会话丢失有关，保留原始摘录并列为剩余诊断项。会话错误不能直接作为 App 崩溃结论。
