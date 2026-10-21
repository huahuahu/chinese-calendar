# 导航状态后续改动：整合结果

- 日期：2026-10-21
- 基线：`4ad58223032e59112b53589baa82534abd832227`（PR #157 合并后的 main）
- 关联：[请求协调状态](015-coordination-state.md)、[呈现 Context 路由](016-readable-context-route.md)、[栈根 Destination](../issue-146-navigation-containers/002-routed-stack-roots.md)
- 范围：汇总上述并行任务及 Scope、primary 选择、alert 按钮 API、注释修订的最终工作区；本次用户已授权统一提交新 PR。

## 最终行为

1. 每个已声明栈都有根 Destination，运行时 path 为非可选数组。读取 Context 不创建栈；缺少根的初始化、呈现或恢复配置被拒绝。删除栈使旧 Context 失效，恢复时仍存在的栈复用原对象。
2. DEBUG SplitView 详情通过共享 destination builder 构建。对象选择从详情根投影，空态为 `.debugSplitEmpty`；换对象清空路径，重复选择保留路径。分类和布局仍归 App，受阻操作不会提前更改它们。
3. 命名栈显式遵守 `NavigationScope`。根选中 `.primary` 时，Router／快照的 `selectedScope` 和 App 的 `selectedTab` 返回 `nil`，选中页面由真实栈状态投影。
4. `NavigationCoordinationState` 集中管理请求确认、已接受的延迟请求及 alert 后的关闭意图。保留已接受 A 与待确认 B 并存、取消 B 不撤销 A、最新请求携带自身确认策略，以及真实关闭／业务动作完成门禁。
5. 呈现 Context 与 Layer 共享轻量的可观察入口记录。失效或层释放后，`route`／`destination` 仍可读取；操作和宿主渲染继续检查 `isActive`。同 ID 的新模态不会使旧 Context 复活。
6. alert 将普通／危险按钮与唯一取消入口分开建模，构造时保证非空。普通按钮按 Action 去重，保留首次顺序、采用最后内容；展示与回传共用同一按钮顺序。
7. 日历领域模型、SwiftData 关系、导入脚本及 Preview 的附带修改为中文注释和术语澄清；没有修改数据 schema、导入逻辑或用户显示文字。导航适配和测试变更另计。

## 接入与恢复兼容性

| 变化 | 调用方迁移 |
| --- | --- |
| `Scope: NavigationScope` | 为原有作用域类型添加协议遵循；协议只继承 `Hashable`，不增加成员 |
| `selectedScope`／`selectedTab` 可选 | 处理 primary 的 `nil`；容器 selection 使用完整 `selectedStack` |
| 根配置必填，换根不接受 `nil` | 外部容器显式声明各栈根；空详情使用空态 Destination，自定义 root 闭包不能代替声明 |
| presentation 路由非可选 | 用 `isActive` 判断能否操作和渲染，不再以 route 是否为 nil 判断生命周期 |
| alert 构造 API 调整 | 使用 `firstButton`／`additionalButtons` 与独立 `cancelButton`，或仅取消按钮的初始化器 |
| 空 path 归一化、无根快照拒绝恢复 | 编码字段保留；不再区分缺失路径与显式空数组，旧无根快照需由调用方补足配置 |

Core 快照保存其管理的根和路径，App 的分类及栏布局仍不由 Core 恢复；App 继续拒绝将 DEBUG 页面当作可恢复业务状态。

## 最终验证

原生 Xcode MCP 使用本工作区的 `ChineseCalendar.xcodeproj`、scheme `ChineseCalendar-iOS`、`chinesedate iPhone 18 Pro Max (885f)`，Simulator ID 为 `16A9CAA7-45CE-46D5-8915-F61531FC617C`。2026-10-21 20:36（北京时间）执行完整测试，包含所需 iOS 构建。

| 检查 | 结果 |
| --- | --- |
| 原生 Xcode MCP `RunAllTests` | 384 passed；0 failed／skipped／not run |
| `./Scripts/format.sh --check` | 297 文件，0 需格式化 |
| `./Scripts/lint.sh` | 286 文件，0 violations |
| `python3 Scripts/validate_localized_copy.py` | 333 项资源通过 |
| `git diff --check` | 通过 |
| Simulator 手动交互、真机、独立 Release、完整独立 review | 本轮未执行；不复用 PR #157 的交互结果证明本轮改动 |

测试覆盖请求协调、primary 投影、栈根与快照约束、Context 生命周期与观察更新、失效宿主不构建页面、alert 按钮顺序和 App SplitView 状态。测试手动推进生命周期及 ImageRenderer 断言不能替代系统动画、宽窄切换或实际点击验证。

测试后仅格式化 `NavigationPresentationHost.swift` 的换行和缩进，去掉空白后与受测文件完全一致；没有修改执行代码。94 个改动源文件的受测／最终 SHA-256、测试明细和检查结果见[整合证据](evidence/navigation-state-integration/validation.json)。015／016 中的 361 项和 43 项结果保留为阶段证据，不代表最终工作区。

构建成功但仍报告测试链接的 sysroot 警告及 `arrowTriangleBranch` 弃用警告，本轮没有处理或宣称消除它们。远端 CI 状态以新 PR 的实际检查为准。
