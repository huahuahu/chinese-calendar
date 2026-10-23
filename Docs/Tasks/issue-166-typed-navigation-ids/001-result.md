# Issue #166：领域身份类型隔离结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #166](https://github.com/huahuahu/chinese-calendar/issues/166)
- 日期：2026-10-22
- 受测产品代码：`cb289ddca44c1f210c48224ac752f5588121c4b7`；构建测试在相同源码工作区完成后提交，本结果与验证脚本单独提交

## 实际结果

六个领域使用独立小值类型，Core 的三个身份提供 public 无参数初始化，底层 UUID 存储保持私有。App 的路由、字典、会话输入与清理投影贯穿业务 ID。`CalendarPresentationSessionID` 保留聚合登记的类别，DEBUG 页面自己的 UUID 保持原用途。

`NavigationSystemAlertID` 将业务与框架确认来源绑定到身份，并用于展示、关闭、完成处理和会话释放。相同底层 UUID 不会使跨来源回调匹配；已有对象身份检查、请求内容去重、结果枚举及日志语义保持。

## 验收证据

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| ID-01 | 已验证 | [独立编译摘要](evidence/compile-negative-summary.json)：真实 NavigationCore / ChineseCalendarUI 模块；正向控制 1/1，跨类比较 15/15 和 API 误传 30/30 均以预期类型错误拒绝 |
| ID-02 | 已验证 | NavigationIdentityTests 与 CalendarIdentityTests：同值 equality、Set 去重、Dictionary 查询；正向 typecheck 也检查六类 Sendable |
| ID-03 | 已验证 | Core 源码与调用链检查；剩余 UUID 仅在 ID 内部存储／初始化；无 `isConfirmation` 或跨领域转换 overload；App/test build 成功 |
| ID-04 | 已验证 | 同 UUID 不同来源的 system alert 值语义和三个生命周期阶段的错误回调测试；既有旧／重复回调测试通过 |
| ID-05 | 已验证 | App 字典、路由、登记集合迁移；同底层值的三类业务身份不合并；年份／下载路由字符串保持 |
| ID-06 | 已验证 | 全部 341 个测试定义、441 次参数化执行通过；涵盖确认、排队、关闭、失效 Context 和同 ID 新对象隔离 |
| ID-07 | 已验证 | README、MIGRATION、API 注释与导航规范更新；原生 Xcode build-for-testing 与 RunAllTests；format 326 文件 0 修改，strict lint 315 文件 0 violation |

环境为 ChineseCalendar-iOS scheme，iOS 27.1 SDK，iOS 27.0 的 `chinesedate iPhone 18 Pro Max (885f)` Simulator。汇总见 [validation-summary.json](evidence/validation-summary.json)，原始 xcresult 精简导出见 [xcode-tests.json](evidence/xcode-tests.json)。

原生 MCP 摘要列出两条带发现阶段随机 ID 的 `No result` 标签；实际 xcresult 为 Passed、441 次执行、0 failure/skip，控制台明确记录 `noticesKeepASingleAcknowledgement(route:)` 三个参数全部通过。这两条为摘要匹配差异，不计为测试失败或跳过。

以上编译证据记录的是本任务提交时的 API。其验证器 `Scripts/validate_navigation_identity_types.py` 已在 Issue #165 收窄公开 API 后退役；历史摘要保留原验证器名称和结果。当前 Core 身份属于内部实现，由 `NavigationIdentityTests.swift` 的 `@testable` 测试验证；App 旧会话身份已随资源所有权迁移移除。

当前普通 `import NavigationCore` 的编译边界由 `Scripts/validate_navigation_public_api.py` 验证。先用相同 Xcode scheme 构建 Debug Simulator 模块，再运行 `python3 Scripts/validate_navigation_public_api.py <Build/Products/Debug-iphonesimulator> <iPhoneSimulator.sdk> arm64-apple-ios26.0-simulator`。脚本先要求支持的公开调用编译成功，随后逐例确认内部类型、事务和已移除投影不可访问；报告与不可编译样例仅生成在忽略的 `.output/navigation-public-api/` 下，不属于正常 target。

## 检查范围与剩余事项

本轮进行了实现者检查、跨模块集成检查、编译和自动测试，没有另外启动完整 review 流程。没有发现需修复的问题。未进行真实 Simulator 点击或真机验证，构建／测试证据不替代交互证据；本次为编译期身份迁移，后续 Issue #164 的独立 Action 改造另有真实交互验收。
