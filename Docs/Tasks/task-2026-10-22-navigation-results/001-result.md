# 导航操作结果与诊断：结果

- 方案：[000-plan.md](000-plan.md)
- 记录日期：2026-10-22
- 代码状态：以下为首次实现验证快照；受测源文件 SHA-256 与基线 commit 见 [source-manifest.json](evidence/source-manifest.json)。完整提交范围及与最新主分支整合后的验证见 [002-integration.md](002-integration.md)。
- 实现状态：已完成

## 实际结果与方案偏差

- 栈命令、根层直接修改和取消确认返回 `NavigationMutationResult`；呈现及关闭返回 `NavigationPresentationResult`；根请求与批准确认返回 `NavigationRequestResult`。拒绝携带枚举原因，正常无操作单独表达。调用方及既有测试已同步迁移，不保留旧 Bool 包装。
- Context 通过窄接口取得拒绝原因；已失效、未声明及不兼容的栈能分别诊断。只保存日志所需的层 ID，不因此保活 Router／层／栈。重复设置合法路径仍为 applied，业务层只在正确的应用或接受状态更新自身数据。
- 层初始化与呈现入口共用配置校验。根 Router 的直接修改方法仍保留原有直接操作语义；需要确认和关闭协调的请求继续使用 submit。
- 所有命令复用 navigation 日志分类。查询与内部过期回调保持安静，转发入口不重复记录；正常流程使用 debug，结构配置拒绝使用 notice。日志记录操作、结果、原因及私有层／栈身份，不输出 Destination。
- 新增两组共 12 个测试，覆盖结构拒绝、事务阻挡、正常无操作、排队与失效上下文。既有生命周期、队列、同 ID 对象隔离及业务状态联动测试继续通过。
- 没有改变确认／队列策略或引入最终界面完成通知。applied 只表示数据已应用，queued 仍可能在所属层失效时被丢弃。

为维持职责和文件结构，根 Router 的直接栈修改集中到 `NavigationRouter+Mutations.swift`；正常无操作也覆盖过期确认／取消。当前 API 与迁移方法见 [README](../../../Sources/NavigationCore/README.md#操作结果与诊断) 和 [MIGRATION](../../../Sources/NavigationCore/MIGRATION.md)。

## 验收证据

工程为 `ChineseCalendar.xcodeproj`，scheme 为 `ChineseCalendar-iOS`，使用共享配置指定的 `chinesedate iPhone 18 Pro Max (885f)`，iOS Simulator 27.0。Simulator ID 为 `16A9CAA7-45CE-46D5-8915-F61531FC617C`。

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| NR-01 | 已验证 | NavigationOperationResultTests、NavigationStackStateTests：具体拒绝原因、栈底 noChange、重复写入接受及拒绝时保持状态 |
| NR-02 | 已验证 | NavigationPresentationResultTests、NavigationLayerInitializationTests：applied／queued、非法配置无部分写入、关闭期间的策略 |
| NR-03 | 已验证 | NavigationOperationResultTests、NavigationPrimaryLayerTests、NavigationCoordinationTests：结构原因、等待确认、真实关闭后应用、过期确认不影响新请求 |
| NR-04 | 已验证 | NavigationAlertSessionTests、NavigationAlertTests、NavigationContextStoreTests：幂等回调、旧 Context 失效、队列及缓存生命周期 |
| NR-05 | 已验证 | 最终测试实际输出 navigation 日志；保留去掉动态身份的[日志样例](evidence/navigation-log-examples.txt)。源码检查确认日志级别、隐私与查询／转发边界 |
| NR-06 | 已验证 | 原生 Xcode MCP BuildProject(buildForTesting: true) 成功；最终 RunAllTests 403 passed、0 failed、0 skipped、0 not run；包含调用方 UI 状态测试 |

最终运行摘要见 [validation.json](evidence/validation.json)。`./Scripts/format.sh --check` 通过，302 个文件中 0 个需要格式修改；`./Scripts/lint.sh` 通过，291 个文件中 0 个违规；`git diff --check` 与当前文档相对链接检查通过。

首次构建未识别刚新增的 SwiftPM 源文件，重新打开工程并重选共享 Simulator 后成功。前一轮工具摘要曾多列 4 条含随机 UUID 参数的无结果条目，原始 xcresult 为 Passed；最终完整运行已经明确报告 403/403、0 not run。

## 验证边界

首次实现验证未运行专项 review、Preview、手动 Simulator 交互或真机验证。测试在指定 Simulator 执行，不能据此声称手动点击或呈现动画已验证。后续提交、专项审查及整合验证状态统一记录在 [002-integration.md](002-integration.md)。
