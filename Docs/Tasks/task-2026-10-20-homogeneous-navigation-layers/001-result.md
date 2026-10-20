# 同构导航层：结果

- 方案：[000-plan.md](000-plan.md)
- 日期：2026-10-20
- 分支：`codex/homogeneous-navigation-layers`
- 代码状态：基于 `765fc18b2fb29b6e3f477d4822d73c55fd8eed7f` 的工作区；源文件及资源指纹见 [source-manifest.json](evidence/source-manifest.json)。
- 状态：实现和本地自动检查完成；Simulator 已验证嵌套打开，关闭回退等交互缺口见下文。

## 实际行为

根层与每层页面模态复用 `NavigationLayer`、`NavigationLayerContent` 和 `NavigationLayerSnapshot`。每层以自己的 Destination 选择页面提供容器，或 Core 提供 primary NavigationStack；页面模态继续递归持有下一层。`NavigationRequest` 以 StackID 寻址，普通 primary 根层也能使用既有确认、关闭完成和延迟请求协调。

删除 Destination 入口权限及未实现的 Core 多栏声明。App 的 `.root` 改为 `.mainTabs`，主 Tab 页面从所在层环境取得选中项与各栈；DEBUG 设置菜单可以 Sheet／全屏打开相同主 Tab 页并继续嵌套。下载附件读取实际所在层，关闭按钮按当前层与栈位置显示。

恢复保留结构检查与业务数据可恢复性检查：普通层仅使用 primary，主 Tab 层检查栈集合、选中项与 path key，递归检查重复 ID、临时业务会话和事务。Tab 根页面可以替换，保存／恢复不要求它等于初始根页面。同种容器归属的根恢复保留栈对象；在页面自带容器与 Core 单栈之间切换时重建栈，使旧栈 Context 失效，根呈现 Context 保留。模态恢复继续生成新对象，旧 Context 不复活。

## 验收证据

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| LAYER-01 | 已通过自动测试 | NavigationDestinationTests、NavigationLayerSnapshotTests：普通根／模态、外部容器根／模态使用同一结构。 |
| LAYER-02 | 已通过状态测试 | Core 不按 Destination 位置拒绝数据；App 测试只证明数据接受，不把它等同于任意嵌套布局可渲染。 |
| LAYER-03 | 自动测试通过；交互部分验证 | 三层主 Tab 状态隔离测试通过。Simulator 完成 Sheet 内切换 Tab、push 西汉详情和继续打开主 Tab 全屏；关闭后的父／根层回读未完成。 |
| LAYER-04 | 自动测试通过；交互部分验证 | 递归关闭、重开、父层状态和根层不可关闭自身由测试覆盖。Simulator 达到根 → 主 Tab Sheet → 主 Tab 全屏；普通子 Sheet 及逐层关闭回退未完成。 |
| LAYER-05 | 已通过自动测试 | 编码往返、根／模态 Tab 换根恢复、深层非法结构原子拒绝、重复 ID、旧模态 Context；根容器归属切换双向失效及同归属复用测试均通过。 |
| LAYER-06 | 已通过状态测试与源码核对 | Tab 后台栈拒绝 present，unscoped 允许同层并列栏目发起；ScopeView 显式开关注入策略。未制作完整 SplitView 产品布局。 |
| LAYER-07 | 自动测试通过；交互未完整验证 | 原有 alert／deep link 协调及新增 primary 请求测试通过；截图确认主 Tab Sheet／全屏单一关闭按钮。下载预览、alert／deep link 的运行回归本轮未完成。 |
| LAYER-08 | 已通过 | 原生 Xcode MCP RunAllTests：325 passed，0 failed／skipped／not run；格式检查 276 文件、严格 lint 265 文件均无问题，本地化 293 项通过，git diff --check 通过。 |

自动测试使用配置中的 `ChineseCalendar-iOS` scheme、`chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0）。最终测试覆盖 [source-manifest.json](evidence/source-manifest.json) 标识的全部源码与资源，结果计数及 34 项重点导航用例见 [final-tests.json](evidence/final-tests.json)。没有将 host SwiftPM 构建作为 iOS 验证。

Simulator 步骤、截图和工具失败记录见 [运行报告](evidence/runtime/README.md)。原生 Xcode 交互两次丢失 session，接管后原层叠状态不再可用于关闭对照；备用 XcodeBuildMCP 对齐相同 Simulator 后可读取界面，但点击设置 Tab 未改变界面。没有取得能将中断归因于 App 的证据，未将工具 success 当作交互通过。运行截图来自最终恢复补丁前的已安装包；交互相关 View 未再修改，最后恢复补丁由上述最终测试覆盖。

## 验证边界与后续

- 本次实现按用户最后澄清区分层入口与内部栈。主 Tab 页在每个根／模态入口取得独立栈；在其自身某个 Tab 的 path／栈根再次嵌套同一个容器会重复绑定同一栈，业务 View 仍须遵守“一层同一栈一个宿主”。本次没有新增 push 容器的独立栈命名空间，也没有恢复入口白名单。
- 外部 SplitView 可使用当前层栈和非排他呈现入口；完整栏目联动、宽窄折叠仍由 #146 负责。
- 新快照使用 `rootDestination + layer` 编码。App 尚未接入跨启动自动持久化，因此没有线上旧快照迁移；需要保留旧编码的宿主应显式迁移。
- Preview 与真机未单独运行；本次没有启动正式 `review-changes` 专项审查。
