# Issue #145：通用作用域 Router 与 App 示例

- 日期：2026-10-07；状态：已实施，正在补充真实交互证据；结果见 [001-result.md](001-result.md)。
- 来源：[用户博客](https://huahuahu.github.io/ios-demo-projects/swiftui-navigation-handling/)及本轮明确要求完善 NavigationCore。该授权替代 004 的不改 Core 边界，承接 005 的通用宿主。
- 依据：[导航规范](../../Conventions/Navigation.md)、[SwiftUI 规范](../../Conventions/SwiftUI.md)。保留当前工作区已有修改，实施前差异已备份到 `.output/issue-145/scoped-router/`。

## 方案

Route 只表示页面身份，所有 present API 接收强类型数据。根 NavigationRouter 保存 Tab path 与模态树；NavigationContext 为根、Tab、模态提供同一种局部操作接口，引用原状态，不复制另一套 path。相同页面在不同作用域调用 push 时只更新当前栈；关闭子模态只移除对应节点，已失效上下文不再可用。

Core 提供 Tab 栈宿主及递归模态宿主，逐层注入上下文，业务只传入 destination builder 和容器策略。演示的多 Tab 页面继续自带根栈。提示使用数据驱动宿主，确认文案由 App 的本地化模块提供，不放入 Core。

外部请求可以选择在有模态时先确认。确认请求只通知当前可见作用域；取消不改变路径或模态，确认后关闭根树，等待根 onDismiss 再导航。请求 ID 防止过期确认授权新目标。关闭过程中到达的新请求仍经过确认策略，不自动覆盖已确认目标。没有活动页面的冷启动直接导航。

快照包含 root、paths、页面身份、节点 ID 和子树；当 scope/destination 遵循 Codable 时支持序列化。恢复只在无活动呈现及转场的根状态执行；不保存 View、ModelContext、回调、提示或未完成请求。App 作为使用示例提供可序列化业务地址，明确临时年份/演示会话不跨进程恢复，不自动改写用户的启动恢复偏好。

App 迁移到通用上下文与宿主，删除业务层重复的关闭动画协调。年份选择保留发起页上下文；演示详情使用局部 Router。增加实际可访问的历史数据模态入口，展示模态内 push 与嵌套呈现，尽量复用现有页面与文案。

## 验收

| ID | 结果与证据 |
| --- | --- |
| SCOPE-01 | Tab 与模态环境获得正确上下文；程序化 push、pop、present、dismiss 不影响兄弟栈；通用状态测试 |
| SCOPE-02 | 多层 sheet/cover、重复打开、失效上下文与关闭动画协调；测试和 Simulator |
| SCOPE-03 | Deep link 确认/取消、重复链接、过期确认、等待关闭、新请求与节点失效；状态测试及真实模态交互 |
| SCOPE-04 | 快照重建树、Codable 往返、恢复后继续导航；临时业务会话边界明确 |
| SCOPE-05 | App 通过同一公开 package API 展示 Tab、模态内部 push、嵌套模态与提示；README 提供独立于日历的示例 |
| SCOPE-06 | iOS 测试、Debug/Release、格式、strict lint、本地化校验及 Simulator；新结果与旧轮证据分开 |

博客的自动关闭策略被用户追加的离开确认要求替代；URL 解析、业务 copy 和数据可用性继续由 App 决定。本次不新增第三方依赖，不启动 PR review 或远程发布。

## 交互发现与必要调整

连续 deep link 实测发现系统 `alert(isPresented:presenting:)` 保留旧文案；旧 ID 保护虽然拒绝错误批准，却导致新请求无法再次提示。sosumi 查询确认新版 iOS 27 item+actions 也忽略展示后数据变化。因此确认宿主集中使用有 Identifiable 替换生命周期的 `alert(item:content:)`，让系统在请求变更时关闭旧提示再展示新提示。这是针对已复现行为的兼容选择；请求确认、ID 和状态仍由 Core 数据驱动，业务页面不接触 Alert。

系统会在确认按钮回调前向 item binding 写回 nil，因此宿主不通过该写回消费请求，由带具体 ID 的显式确认/取消动作处理。年份选择器实测在首次布局前尝试 scrollTo，改为等待有效滚动几何后定位，并观察选中年份；保留年份与世纪的 ID 类型隔离，不加固定延时、不另存业务选择。

## 完成结果

实现、最终 244 项 iOS 测试、Debug/Release 构建及 Simulator 验收见 [001-result.md](001-result.md)。接入示例与 API 迁移见 [NavigationCore README](../../../Sources/NavigationCore/README.md)，实际交互证据及修复前后版本边界见[设备验证报告](evidence/scoped-router/runtime-report.md)。
