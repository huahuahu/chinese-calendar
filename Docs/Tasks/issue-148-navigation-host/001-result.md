# Issue #148：根导航宿主配置结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #148](https://github.com/huahuahu/chinese-calendar/issues/148)
- 日期：2026-10-19
- 基线：`63eb6797`；分支：`codex/issue-148-navigation-host`；验收源码快照见 [source-manifest.json](evidence/source-manifest.json)。

后续统一页面构建方法与共享数据环境的调整及独立验证见 [002-unified-destination-builder.md](002-unified-destination-builder.md)。本文件的证据仅对应首次迁移版本。

## 实际实现

`NavigationHostConfiguration` 定义普通页面、模态及其 push 后代、容器策略、确认／alert 文案和业务动作。根 `navigationHost` 注入配置并安装根呈现宿主；各 `NavigationScopeView` 按所在环境读取规则，在自己的 NavigationStack 注册 destination。sheet、full-screen 和递归节点自动继承配置，多 Tab 模态保留内部栈和本层唯一呈现宿主。

环境保存方法式配置的值，不保存裸 builder 闭包或进程级注册。相同路由类型的独立导航树可以覆盖自己的配置。View 类型只在 `NavigationConfiguredDestination` 的构建边界擦除。Swift 6 的日历路由采用 MainActor 隔离，因此业务配置显式使用 `@MainActor` 协议遵循；环境键使用无状态、Hashable 的泛型值作为 KeyPath 下标。

`CalendarNavigationConfiguration` 收拢原根栈与模态构建入口，以及提示和清理回调。三个根 Tab、下载演示的两个 Tab、`SampleNavigationPreview` 均删除重复映射。模态页面仍从当前 store coordinator 注入数据环境；年份选择器仍按 session ID 使用发起页的 selection、ModelContext 和回调。模态 push 根据层 ID 选择构建入口，关闭动画期间不会因 Context 已失效而切回普通页面映射。

Router、栈／呈现 Context、状态树、快照与年份选择会话无改动。Core README 的完整双 Tab／多 Tab 模态／独立 Preview 示例和导航规范已同步。原仅检查 builder 初始化的测试由新的配置环境、实际页面渲染和状态隔离测试替代。

历史页的示例数据／空状态 Preview 也使用 `SampleNavigationPreview`，使预览中的值导航有真实栈宿主。为通过 Xcode Preview 生成代码的重载解析，将该页 `ForEach` 的函数引用改为显式尾随闭包，保留原 row 函数与数据身份；修复前诊断和修复后截图单独记录。

## 验收证据

工具上下文：原生 Xcode MCP，`ChineseCalendar.xcodeproj` / `ChineseCalendar-iOS`，共享配置指定的 `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0。

| 验收项 | 状态 | 证据与范围 |
| --- | --- | --- |
| HOST-01 | 通过 | App 与测试目标已构建；根历史 NavigationLink、设置 push 已实际交互；新增宿主测试通过 |
| HOST-02 | 通过 | sheet push/pop、嵌套 full-screen 已实际交互；临时入口补验了多 Tab 模态两栈 push 与子模态，随后移除入口 |
| HOST-03 | 通过 | 根 Tab 和多 Tab 模态的页面 ID／路径实际保持；一栈 pop 不影响另一栈；独立环境、失效 Context 自动测试通过 |
| HOST-04 | 通过 | 年份选择回传与重开已实际交互；第二个日历页改为 2028 后返回，根页仍为 2027；发起页 selection／ModelContext／旧回调回归测试通过 |
| HOST-05 | 通过 | Router／Context 源码无差异；连续 alert、业务提示后离开确认、取消／批准已实际交互；现有协调测试通过 |
| HOST-06 | 通过 | README／规范本地链接检查通过；历史页两个独立 Preview 实际渲染通过；最终 format／lint／diff 检查通过 |

移除临时入口、完成历史页 Preview 接入后，全量回归为 **285 通过、0 失败、0 跳过、0 未运行**，包括 4 个新宿主测试。随后仅把新增渲染测试的 `uiImage` 断言换为跨平台的 `cgImage`，4 个宿主测试定向复验全部通过；App 实现未再改动。逐项摘要见 [tests.txt](evidence/tests.txt) 和 [host-tests.txt](evidence/host-tests.txt)。

最终源码的 format 检查为 0/267 文件需修改，严格 lint 为 256 文件、0 violations；`git diff --check` 通过。构建、安装、测试产物位置和源码指纹见 [automatic-checks.json](evidence/automatic-checks.json)。临时多 Tab 入口仅为测试已有栈的路由能力，差异保留为 [modal-tabs-harness.patch](evidence/modal-tabs-harness.patch)，已从源码移除并按原字节核验，最终版也已重新构建安装。

正式版复验：从已 push 的 sheet 直接关闭，父栈 ID 与路径不变；重开为新模态 ID、空路径。第二个日历页选为 2028 后返回，根页仍保留 2027，再用“今天”恢复当前日期。下载演示的两个 Tab 均无临时动作入口，关闭后原有完整数据仍在；最新朝代列表的 NavigationLink 可进入秦详情。最终设备 session `Issue 148 Final` 已结束，返回 `Session stopped`。

实际交互的步骤、截图与版本边界见 [runtime-report.md](evidence/runtime/runtime-report.md)，Preview 的像素检查和自动呈现快照限制见 [preview-report.md](evidence/previews/preview-report.md)。结构测试、SwiftUI 渲染测试、Preview 和触摸交互分别记录，不相互替代。

## 审查与交付边界

本任务为实现，没有启动 `review-changes` 专项审查。设备验证使用 `device-interaction` 技能要求的专用子代理。代码、文档与本轮关键验收证据一同交付，发布及合并状态以关联的 GitHub PR 为准。真机、VoiceOver 与其他系统版本不在本轮验证范围。
