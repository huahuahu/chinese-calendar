# Issue #164：独立提示 Action 结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[Issue #164](https://github.com/huahuahu/chinese-calendar/issues/164)、前置 [PR #168](https://github.com/huahuahu/chinese-calendar/pull/168)
- 日期：2026-10-23
- Action 实现：`5fc6a1043eebd119d25bd068a234abdaf95a7be4`
- 存储修复：`c851e37260508ee22dfcaeb8995be4c140b4824f`
- 状态：实现、本地构建、测试、独立源码审查及必要 Simulator 交互均通过；清空崩溃已在同一 Simulator 复验修复。

## Action 接口与生命周期

`NavigationAlertRoute` 不再为整树规定 Action。宿主通过 `NavigationAlertDefinition` 的泛型初始化器，将 `NavigationAlertContent<Action>` 与同类型异步 handler 绑定。系统展示边界只擦除已配对的按钮动作，不使用 `Any`、`AnyHashable` 或运行时 route/action 配对。Router 继续只持有路由、身份和协调状态。

App 的清理确认、普通通知与 DEBUG 导航各有独立 Action。处理函数完整 switch 自己的选项，取消、结果提示、错误消息释放和当前层 Context 语义保持。框架离开确认仍使用独立的布尔动作。

UIKit 真实 dismissal completion 后先取得一次处理权，再等待按钮业务动作，最后释放 alert 会话并推进队列。过期、重复及失效 Context 回调不能开始业务动作，也不能释放新的提示会话。

## 首轮验证及清空崩溃

原生 Xcode App/test build 成功；358 个测试定义、461 次执行通过，0 failure、skip、notRun。独立编译检查使用真实 iOS 模块：正向控制 1/1，错误 handler 双向、错误普通按钮和错误取消按钮 4/4 均被预期的类型错误拒绝，见 [编译摘要](evidence/compile-negative-summary.json)。format 检查 334 个文件无修改，strict lint 检查 323 个文件无违规。

独立源码审查覆盖泛型配对、生产系统适配、真实关闭与异步门槛、旧／重复／失效回调和 App 迁移，在记录的 30 文件快照中未发现可行动问题。该结论不代替交互验收，也不覆盖随后增加的存储修复。

指定 iOS 27.0 Simulator 的真实点击通过普通通知、连续提示、导航选项取消及执行、模态离开确认取消及继续，以及清空取消。确认执行清空后 App 崩溃，未能验证成功结果提示。完整的首轮结论保留在 [交互记录](evidence/README.md)，崩溃主线程摘录见 [clear-crash-stack.json](evidence/clear-crash-stack.json)。

直接原因是旧 `ChineseLunarMonth.days` 在所属上下文失效后被 `LunarDayGrid` 读取；清理日志同时记录在用 SQLite 被删除。存储替换与日历网格源码在 Action 改造前后没有变化；尚未在基线上运行相同交互，因此不声称已实验证明基线同样崩溃。修复范围和原因已补入方案。

## 验收状态

| 验收项 | 状态 | 证据及边界 |
| --- | --- | --- |
| ACT-01 | 已验证 | 独立 Action 的配置测试、源码完整 switch 及通知／导航实际点击 |
| ACT-02 | 已验证 | 真实 iOS 模块 1 个正向控制、4 个独立编译拒绝样例 |
| ACT-03 | 已验证 | App 全部提示迁移与业务动作自动测试通过；修复后真实 full→base、清空取消、成功结果确认及重复 base 清空通过 |
| ACT-04 | 已验证 | 生产转换入口测试覆盖按钮对应、取消、去重、异步挂起、旧／重复及失效回调 |
| ACT-05 | 已验证 | 最终 App/test build、365 个测试定义／469 次执行全部通过；format 337 文件、strict lint 326 文件无违规 |
| ACT-06 | 已验证 | 首轮实际点击证据覆盖两类 Action、串行提示和模态离开确认 |
| ACT-07 | 已验证 | README、MIGRATION、API 注释、导航规范、存储布局与生命周期文档及本结果已更新 |

## 存储修复及最终验证

存储替换改为独立 generation 目录与原子的当前目录指针。候选库准备且打开成功后才发布，失败保留旧版本；下载结果携带已验证容器。解析当前目录到打开容器之间由短期读 lease 保护，已打开容器以弱引用登记。清理先取消并等待实际安装任务退出，再恢复基础库，避免被取消的生产任务晚到发布。

页面内容按实际容器身份重建，并在旧页面生命周期内持有原容器。根页与递归模态共用这个边界，外层导航宿主继续处理真实关闭、结果提示和等待中的导航。即使两次安装使用相同 artifact，容器身份仍会变化并清理旧年份选择会话。

旧库只有在非当前、非准备中且没有读 lease 或活跃容器时才回收。成功清理立即恢复基础数据；若退出中的页面或 Context 仍保活旧容器，磁盘回收可以稍后完成，页面释放、后续切换及冷启动会再尝试。当前登记保护同一 App 进程；未来若新增 Widget 等独立读库进程，必须先补跨进程协调。详见[存储文档](../../data%20model/swiftdata-seed-store.md)。

最终验证绑定上述存储修复 commit，测试前后和设备交互使用的 326 个 Swift 文件合并 SHA-256 为 `1e178855c4269de3bbe28acad76c1c37ca5135b6f41eceefbef931263b3b72c9`。原生 build-for-testing 和 InstallAndRun 成功；[原始 xcresult 摘要](evidence/xcode-tests-final.json)记录 365 个测试定义、469 次执行、0 failure／skip／notRun。测试包括旧 flat 与 generation 容器仍持有月份关系时换库、新库独立读取、读 lease、准备中目录、失败和取消不发布，以及同 artifact 新容器身份。完整检查摘要见 [validation-summary.json](evidence/validation-summary.json)。Action 类型边界源码在修复中未改变，复用先前的 1 个正向控制和 4 个编译拒绝样例。

修复后经正常 UI 下载 207,097,856 字节完整数据，实际加载当月日格，再到设置确认清空，成功结果提示可关闭，随后日历显示需要完整日期数据，朝代与设置继续正常。清空取消保留完整数据，基础数据状态再次清空也成功。进程持续 Running，当前日志没有 `vnode unlinked`、`invalidated open fd` 或 `ModelContext.reset`。补充交互证据由[修复复验记录](evidence/store-replacement/README.md)保存；首轮失败截图和日志继续保留。

模态内连续提示 1→2 顺序正确；在模态设置中打开清空确认前，最后一次捕获的下载进度为 88%，确认框显示时背景为 92%；实际执行后显示“正在清空”，约 16 秒后记录清空成功并出现结果提示。确认后模态仍能切换至基础数据日历并正常关闭回根设置。整个复验进程 PID 为 68489，持续 Running，末次控制台查询上述 SQLite／SwiftData 错误及 Fatal error 均为 0。第二次下载的传输／安装日志早于 UI 进度结束，因此本轮证明的是“下载状态中清空”及等待后的成功行为，未证明仍在网络传输时的取消，也没有对发布临界点注入竞争。取消并等待实际安装任务的顺序另由源码审查确认。

## 审查与验证边界

两次独立源码审查分别覆盖 Action 改造的 30 文件快照和存储修复的 11 文件快照，哈希复核一致，未确认可行动缺陷或强制规范违规。主 Agent 核对报告及代码，并将设备发现的清空崩溃作为必要修复处理。

- 安装生产任务取消并等待的完整竞争时序由源码追踪证明顺序；自动测试直接覆盖已取消的发布入口，没有注入整个下载链路的竞争。
- 失败测试覆盖候选 manifest 准备失败，原子指针写入失败由代码和原子写入语义审查，未做故障注入。
- 下载失败和清理失败的提示由配置／业务自动测试覆盖，没有人为制造真实设备错误。
- 第二轮调试菜单的“导航测试”入口按层级 hitPoint 重试仍未展开，保留为交互观察，未归因为本次修复缺陷。首轮离开确认已有完整通过证据；第二轮未重复该路径。
- 未进行真机验证；构建、自动测试、源码审查及 Simulator 交互分别记录，不相互替代。

## CI 本地化扫描补修

[PR #169](https://github.com/huahuahu/chinese-calendar/pull/169) 首轮 CI 的格式检查、SwiftLint 和 Test job 均通过；`Lint and Format` job 在 `Verify localized copy` 步骤失败。原因是容器身份字符串新增 `ObjectIdentifier(container)` 后，扫描脚本仍使用旧的精确例外；缺失数据库时的诊断根路径 `/` 也被误判为界面文案。

修复只同步该文件的两项技术字面量例外，不豁免整个文件，也不改动产品源码或本地化资源。本地重新核对 337 项资源、22 个生产 UI 字符串通过；已有 App 测试与交互证据继续对应同一份产品源码。远程检查结果以 PR 当前状态为准。
