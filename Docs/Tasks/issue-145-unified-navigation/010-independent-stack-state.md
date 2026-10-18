# 独立栈状态与上下文依赖

- 日期：2026-10-13；状态：实现完成，自动检查与本次栈绑定的 Simulator 验证通过。
- 承接 [009](009-separate-context-apis.md)。用户确认继续拆开内部职责，移除 NavigationContext 对 Router 和 NavigationLayer 的直接依赖。

## 方案

1. 新增内部 NavigationStackState，仅保存一个栈的根 destination 和 push path。NavigationLayer 组合栈对象与子模态；roots/paths 字典变成快照与兼容 API 的投影，不保存第二份路径。
2. NavigationContext 弱引用栈状态，接受只包含 isActive/canMutate 判断的 NavigationStackAccess。该接口不认识 Router、层、模态或确认请求；Router 在创建上下文时用弱捕获提供判断。
3. 上下文按原栈对象缓存。整批路径替换及根快照恢复更新原栈，保持根 Context 的生命周期；模态关闭和同 ID 恢复继续使旧 Context 失效。入口及判断均不持有 Router 或已关闭层。
4. 仅取得一个空栈入口不能改变持久化快照。栈状态用可选 path 保留“未记录路径”和“显式空路径”的区别，对外 path 仍为数组。
5. 页面两个环境 API、呈现宿主和快照格式保持兼容。验证独立栈操作、跨 API 单一状态、Observation 更新、路径替换、恢复和现有导航事务。

## 验收

- NavigationContext 的存储属性和实现不依赖 NavigationRouter、NavigationLayer 或呈现状态。
- 栈对象是根身份及路径的唯一运行时来源；Context 可以在没有 Router 或模态层的情况下通过窄接口使用。
- 缓存身份、根路径批量替换、稀疏快照、同 ID 模态恢复、关闭失效、Router 释放、确认／关闭门禁均有回归验证。
- 原生 Xcode 构建测试及格式、lint、差异检查；运行时交互证据与自动测试分开记录。

## 结果

`NavigationContext` 已移除 Router／Layer 属性，只弱引用独立栈状态并接受 `NavigationStackAccess`。访问约束只有两个同步判断，Router 的工厂使用弱捕获注入实时身份与事务检查；Context 不需要知道操作被阻止是否源于模态。`NavigationPresentationContext` 继续负责层级呈现，两种页面环境的公开 API 不变。

`NavigationLayer` 通过栈对象字典组合路径和呈现；roots/paths 是计算投影。Router 的单栈读写直接访问目标栈，避免每次修改路径时读取并重写其他栈。根路径整体替换和根快照恢复保留已有栈对象；恢复模态则创建新层和新栈。内部可选 path 保留稀疏快照语义，获取上下文不写入空路径条目。没有增加快照字段或业务状态。

- 代码状态：`codex/issue-145-unified-navigation`，HEAD `88e3b74ae7bab044389a9a471346e16f9880bd1c` 加未提交工作区；本轮对应 [源码 SHA-256](evidence/independent-stack-state/source-sha256.txt)。
- 环境：`ChineseCalendar-iOS`，`chinesedate iPhone 18 Pro Max (885f)`，Simulator ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0。

| 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| 栈上下文内部依赖分离 | 已验证 | 源码仅依赖 NavigationStackState、NavigationStackAccess 和栈 ID；新增测试在没有 Router／Layer 时验证 path、push/pop 与访问许可 |
| 单一栈状态与 Observation | 已验证 | 跨入口读写、整批替换后 Context 身份不变；观察 home.path 时，history.push 不触发，home 路径修改触发 |
| 快照与生命周期 | 已验证 | 获取上下文不改变快照、Codable 往返、根 Context 恢复后仍连接；已有测试覆盖同 ID 模态恢复、失效入口不能取得新栈、Router 释放及后台 Tab 呈现限制 |
| 确认及关闭事务 | 已验证 | 新测试覆盖待确认时禁止路径修改、取消后恢复操作、等待关闭期间继续阻挡、根关闭完成后应用目标；既有导航请求测试全部通过 |
| iOS 测试及 App 构建 | 已验证 | 原生 RunAllTests：263 passed，0 failed/skipped/not-run，含新增 6 项测试；BuildProject 成功，无 errors；见 [测试摘录](evidence/independent-stack-state/tests.txt)及[工具结果](evidence/independent-stack-state/validation.json) |
| 静态检查 | 已验证 | 全量 SwiftFormat：0/245 files require formatting；strict lint：234 个文件、0 violations；git diff --check 通过，见[检查结果](evidence/independent-stack-state/static-checks.txt) |
| Simulator 实际交互 | 本次栈绑定已验证 | 设置栈连续 push 后 pop：深度 1 → 2 → 1、恢复原页面 ID；sheet 栈独立 0 → 1 → 0；关闭 sheet 后回到原设置 Tab、深度 1 和原页面 ID。见下方本轮证据，009 的交互结果仅保留作历史记录 |

### 本轮 Simulator 证据

原生 Xcode 安装并运行本轮源码，交互期间 App 进程 PID 保持为 `75149`，没有会话丢失或观察到的异常退出。通过设置页的 Debug 菜单进入导航测试页，复用正式栈与呈现宿主：

- 设置栈：[首次 push](evidence/independent-stack-state/runtime/04-settings-push-first-hierarchy.txt) 的页面 ID 为 `330B7B16-3AB6-4DE0-A732-0D926D2963DE`、深度 1；[再次 push](evidence/independent-stack-state/runtime/05-settings-push-second-hierarchy.txt) 为新页面 ID、深度 2；[pop 后](evidence/independent-stack-state/runtime/06-settings-pop-restored-hierarchy.txt) 恢复原 ID、深度 1。
- 模态栈：[sheet 根页](evidence/independent-stack-state/runtime/08-sheet-settled-hierarchy.txt) 的页面 ID 为 `94A6F0AD-E8CE-4048-B8B5-A9D8A7D005BD`、深度 0；[模态内 push](evidence/independent-stack-state/runtime/09-sheet-push-hierarchy.txt) 为新页面 ID、深度 1；[pop 后](evidence/independent-stack-state/runtime/10-sheet-pop-restored-hierarchy.txt) 恢复 sheet 根 ID、深度 0。已检查[稳定 sheet 截图](evidence/independent-stack-state/runtime/08-sheet-settled-screenshot.png)。
- [关闭 sheet 后](evidence/independent-stack-state/runtime/11-sheet-close-hierarchy.txt)，设置 Tab 仍为 Selected，页面 ID 与深度恢复为首次 push 的值；[截图](evidence/independent-stack-state/runtime/11-sheet-close-screenshot.png)显示返回原页面。

以上只验证本次独立栈状态与 SwiftUI 绑定相关流程。本轮未重跑嵌套 full-screen、Deep Link 提示点击、下载多 Tab 和年份选择器交互；Deep Link 时序有自动测试覆盖，不能据此宣称完整系统转场回归完成。交互结束后调用 EndSession 返回“Session doesn't exist anymore”，无已知待清理会话。

本次没有修改业务 View 或呈现宿主，没有运行 Preview、Release 或真机验证；未执行独立代码 review，未提交或推送工作区改动。
