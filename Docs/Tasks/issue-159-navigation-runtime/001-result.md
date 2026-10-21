# NavigationCore 运行时导航与 Context 生命周期：结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #159](https://github.com/huahuahu/chinese-calendar/issues/159)、[Issue #158](https://github.com/huahuahu/chinese-calendar/issues/158)、[PR #161](https://github.com/huahuahu/chinese-calendar/pull/161)
- 记录日期：2026-10-22
- 实现版本：`76284df6973fb55c9de241398bbf6548ebf4803c`；后续仅补充 `NavigationLayerID` 说明性注释与本验收记录。实际源码校验值见 [source-manifest.json](evidence/source-manifest.json)。

## 实际结果与方案偏差

删除 `NavigationSnapshot`、`NavigationLayerSnapshot`、`NavigationPresentationSnapshot`、Router 快照与恢复接口、CalendarRouter 恢复适配及相关专属编码支持。正常创建根层和模态改用内部可失败的 `NavigationLayer` 初始化，先完整校验选中栈、根和 path，再建立状态；非法 `present` 不改变已有导航树。

`NavigationContextStore` 由每个 Router 独立持有，统一管理栈、层与发起栈呈现 Context。Store 不参与界面观察，Context 和访问闭包保持弱引用；缓存命中核对原状态对象。模态移出树后立即失效，真实 dismiss 完成后统一清理三类缓存。旧入口不能覆盖同 ID 新状态的有效缓存；外部持有旧层 Context 不再连带持有其 scoped 缓存。

#158 原先的恢复成功清理触发点和恢复兼容测试，随 #159 删除恢复能力而不再适用。测试改用正常初始化、现有查询和最小内部节点构造；保留运行时状态、事务、同 ID 隔离和释放断言。没有新增公开替代快照或跨启动恢复方案。App 分栏分类和栏目状态继续由 `CalendarHomeCoordinator` 管理。

README、迁移指南、导航规范同步当前能力，相关历史任务仅补充后续决策链接，保留其原有实施和验证事实。

## 验收证据

| 验收项 | 状态 | 工具、环境、版本与证据 |
| --- | --- | --- |
| NR-01 | 已验证 | Sources/Apps Swift 调用方扫描没有完整快照、restore、restorableSnapshot、supportsStateRestoration；独立运行时契约审查通过 |
| NR-02 | 已验证 | `NavigationLayerInitializationTests` 比对原初始化约束，覆盖根/模态及非法路径原子拒绝；本轮 iOS 自动测试通过 |
| NR-03～06 | 已验证 | 新增 7 项 `NavigationContextStoreTests` 全部通过，验证三类身份、跨 Router/Tab/层隔离、弱引用释放、嵌套清理和同 ID 旧入口保护 |
| NR-07 | 已验证 | Core/App 导航与分栏回归通过；确认/alert 协调状态机未改；原始测试结果见 [tests.json](evidence/tests.json) |
| NR-08 | 已验证 | 指定 Simulator 完成代表性 Tab、push/pop、嵌套模态、重开、确认取消/批准和 alert 队列；见[交互记录与截图](evidence/runtime.md) |
| NR-09 | 本地静态检查与构建通过 | 原生 Xcode App 构建启动、`BuildProject(buildForTesting: true)` 成功；format 0/295，lint 0/284；本地化 333 项与 21 项既有字符串例外；schema 919377 条；155 个文档链接；diff --check 通过 |

验证环境为共享配置指定的 `ChineseCalendar-iOS`、`chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`），使用原生 Xcode MCP。首次交互会话返回 `Session with that key doesn't exist`，重建会话后安装启动成功。源码、构建、自动测试与交互结论分别记录；没有用测试编译替代执行结果。

## 审查结论与剩余事项

对实现提交分别进行运行时契约、Context 生命周期两条独立审查，两条均完成且未发现可操作缺陷或强制规范违规。主 Agent 复核调用链与证据后确认结论；审查时列出的测试、交互和结果文档待核实项已完成。后续增量只有 `NavigationLayerID` 说明性注释与验收文档，主 Agent 单独核对，没有改变运行时契约。完整审查报告保存在本地忽略目录 `.output/reviews/issue-159-158-20261022/round-01/`。

原生 `RunAllTests` 的 `.xcresult` 回读为 **294 个测试方法、391 次执行全部通过，0 失败、0 跳过**。MCP 汇总额外保留了 4 个发现阶段随机 UUID 参数的 `No result`；检查原始结果树确认相关 3 个参数化方法的 13 个实际参数实例均为 `Passed`。定向复跑也受到发现身份缓存影响，因此以完整执行的原始结果包为准，没有将汇总残留计作漏跑或通过。两种计数和相关参数证据保存在 [tests.json](evidence/tests.json)。

远端 CI 与合并状态以 [PR #161 检查](https://github.com/huahuahu/chinese-calendar/pull/161/checks) 为准，合并前必须确认最终提交的检查结果。

未验证真机、iPad/Duo 宽屏两/三栏、拖拽关闭 Sheet、真实系统 URL 入口和独立“从 Alert 按钮跳转”按钮。代表性导航/模态验收已通过；分栏状态、URL 解析、alert 动作与关闭事务另有自动测试覆盖。未改变 UI 布局，也未新增跨启动恢复产品功能。
