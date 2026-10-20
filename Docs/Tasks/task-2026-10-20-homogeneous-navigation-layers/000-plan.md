# 同构导航层：方案

- 状态：实现完成，自动检查通过；交互验证边界见 [结果](001-result.md)
- 日期：2026-10-20
- 前序：[Destination 容器与层入口](../issue-152-destination-containers/000-plan.md)、[呈现层与多栈](../issue-145-unified-navigation/008-presentation-layers.md)
- 依据：用户确认根层与每层模态使用同一结构，每层选择由页面提供导航容器或由 Core 提供 NavigationStack；页面不声明允许出现的位置。此决定替代 #152 的入口白名单和 Core 多栏预留声明。

## 目标与设计

1. 每层保存入口 Destination、栈集合、当前选中栈和可选的下一层呈现。根层和模态层使用相同初始化、内容渲染和快照结构。最底层没有父层，关闭自身返回 false；该生命周期差异不改变层内容模型。
2. `providesNavigationContainer` 只表达容器归属：true 由 Destination 对应的 View 组织 TabView／NavigationSplitView 等结构；false 由 Core 提供 `.primary` NavigationStack。删除 `allowedNavigationEntries`、`NavigationDestinationEntry`、`supportsNavigationEntry` 和未实现的 Core 多栏容器声明。
3. Router 根入口与 present 使用一致的 initialStack、rootDestinations、paths 参数。原有面向根 Tab 的便利 API 可投影统一状态，但不再限制根层必须是命名栈。普通根层和普通模态可以替换栈根，层入口保持不变。
4. 根快照复用 `NavigationLayerSnapshot`，递归保存每层栈和下一层。恢复先验证完整结构、重复 ID 与事务状态；页面数据的可恢复性仍由业务适配层判断。同种容器归属的恢复保留根栈对象连接；容器归属切换时重建栈、失效旧根栈 Context，避免旧宿主读取已经移除的根页。恢复后旧模态 Context 仍保持失效。
5. App `.root` 重命名为 `.mainTabs`，表示页面内容。主 Tab 页面使用当前层的 presentation 和 selectedStack，避免操作全局根层。模态关闭控件根据运行时层／栈位置决定，不再通过入口白名单推断。
6. 页面提供的 Tab 容器保留选中栈的呈现约束；同时可见的 SplitView 栏目可显式使用本层的非排他呈现上下文。完整栏目联动和折叠设计继续由 [#146](https://github.com/huahuahu/chinese-calendar/issues/146) 负责。本次不引入生产多栏产品布局。
7. 使用可触达的 DEBUG 场景验证主 Tab 模态、普通模态以及递归嵌套；保持业务 alert、外部导航及真实 dismissal 完成后的请求协调。

## 验收

| ID | 场景与预期 | 验证 |
| --- | --- | --- |
| LAYER-01 | 根层和模态均能以 Core primary 单栈或页面自带容器初始化 | 状态测试、源码 |
| LAYER-02 | 同一 Destination 不按 root／stackRoot／push／presentation 拒绝 | 状态测试 |
| LAYER-03 | 根主 Tab 与模态主 Tab 的选中项、路径及下一层互不影响 | 状态测试、Simulator |
| LAYER-04 | 三层以上递归呈现、关闭、重开保留父层状态；根层不能关闭自身 | 状态测试、Simulator |
| LAYER-05 | 根与模态快照编码往返，替换栈根可恢复；非法结构拒绝且不部分写入；旧模态 Context 不复活 | 状态测试 |
| LAYER-06 | Tab 后台栈不能呈现；外部同时可见栏目可显式使用本层呈现入口 | 状态／宿主测试 |
| LAYER-07 | 关闭按钮、alert、deep link、现有下载预览正常 | 既有测试、Simulator |
| LAYER-08 | 格式、lint、iOS 构建与测试通过；规范和示例与最终 API 一致 | 脚本、原生 Xcode MCP |

## 交付

在当前 worktree 的 `codex/homogeneous-navigation-layers` 分支实施，提交聚焦的变更并创建 PR，不自动合并。结果记录源码、自动测试、Preview、Simulator 和真机证据边界。
