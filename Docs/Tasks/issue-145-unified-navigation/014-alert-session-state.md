# Issue #151：提示会话生命周期枚举

- 关联：[Issue #151](https://github.com/huahuahu/chinese-calendar/issues/151)，承接 [011：统一业务 alert 与导航协调](011-unified-alerts.md)。
- 日期：2026-10-19；2026-10-20 补充交互重试。状态：实现完成，自动验证通过；Simulator 已验证连续 alert、按钮跳转及 sheet／full-screen 上离开确认的取消与批准。
- 验证基线：`4f386d06`；分支：`codex/issue-151-alert-session-state`；验证源码以 SHA-256 清单标识，后续实现与测试提交为 `11405e8f`。

## 方案与决策

当前两个可变布尔值允许表达“尚未关闭却在处理完成回调”的非法组合，尚无证据表明正常宿主调用会产生它。本次只收紧 `NavigationAlertSession` 的状态建模与转换契约。

- 生命周期使用 `State.presented → dismissing → handlingCompletion → nil`。`presented` 表示会话已占用，不承诺展示动画结束；`isConfirmation` 继续独立表示提示种类。
- `alertWillDismiss` 仅接受 `presented`；`beginAlertCompletion` 仅接受 `dismissing`；`alertDidDismiss` 仅接受 `handlingCompletion`。各入口继续核对 ID 与 Context 有效性；无效或重复回调直接忽略。
- 生产宿主已经先接收 UIKit completion，再通过 `beginAlertCompletion` 获取一次性处理权，等待异步业务动作后调用 `alertDidDismiss`。因此选择严格前置状态，不保留测试中从 `dismissing` 直接释放的简化路径。
- 现有 alert 协调测试改为遵循宿主顺序；增加乱序、重复、错误／过期 ID 和失效 Context 的回归测试。保持 Router 的 FIFO 队列、模态关闭及外部导航等待逻辑。
- 遵循 [NAV-04／NAV-05](../../Conventions/Navigation.md) 与[通用规范](../../Conventions/Common.md)。不修改 UIKit 宿主、业务文案或呈现 API。

## 验收与验证计划

| ID | 验收点 | 验证方式 |
| --- | --- | --- |
| AS-01 | 生命周期只有三个合法枚举状态；提示种类独立 | 源码检查、业务／确认提示生命周期测试 |
| AS-02 | 未关闭不能进入 completion；未处理 completion 不能释放会话 | 乱序回调测试，断言会话及待处理导航保持不变 |
| AS-03 | 重复关闭不倒退、不重复获得业务动作处理权 | 重复回调测试 |
| AS-04 | 错误 ID、旧提示回调和失效 Context 不影响现有／新会话 | 各阶段错误 ID、换新提示及失效 Context 测试 |
| AS-05 | 关闭与业务动作期间保留会话；释放后 FIFO、模态关闭和外部导航恢复 | 既有 alert 协调测试及新增等待断言 |
| AS-06 | 集成与静态检查通过；区分测试和界面证据 | 原生 Xcode MCP 测试、格式、严格 lint、diff 检查；另行记录 Simulator 交互 |

## 实际结果

生产代码仅修改 `NavigationAlertSession.swift` 与 `NavigationPresentationContext+Alerts.swift`，按方案用单个状态及三个入口的前置约束替换生命周期布尔值。Router 与 UIKit 宿主保持原实现；Core README 补充宿主契约。`isConfirmation` 保留，没有方案偏差。

既有 `NavigationAlertTests` 的正常关闭流程全部显式经过 `beginAlertCompletion`，确认／业务动作也在取得处理权后执行。新增 `NavigationAlertSessionTests` 的 4 项测试通过参数化覆盖 9 个执行场景；既有测试补充关闭、动作执行期间的等待断言，以及重复关闭后的处理权检查。

实现与测试已提交为 `11405e8f`。此前在未提交工作区完成的自动测试与交互验证以[源码 SHA-256](evidence/alert-session-state/source-sha256.txt)标识；合并前再次核对七个源码／宿主／测试文件，均保持一致。

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| AS-01 | 已验证 | 类型只包含三个生命周期枚举值；业务与确认提示两组完整转换测试通过 |
| AS-02 | 已验证 | 提前 `beginAlertCompletion` 返回 false；`presented`／`dismissing` 收到 `alertDidDismiss` 保留会话；待处理历史导航不执行 |
| AS-03 | 已验证 | 重复 `alertWillDismiss` 保留 `handlingCompletion`；后续 `beginAlertCompletion` 返回 false，不能重复取得业务动作处理权 |
| AS-04 | 已验证 | 每阶段错误 ID、每阶段旧提示回调、同 ID 恢复后的旧 Context 测试通过 |
| AS-05 | 已验证（单元测试）；六项实际交互通过 | FIFO、业务结果提示、sheet／full-screen、取消／批准导航、模态关闭、快照阻塞等既有协调测试通过；本轮 Simulator 另验证下方六项流程，未模拟耗时异步业务动作 |
| AS-06 | 自动验证及六项 Simulator 交互通过 | 原生 Xcode MCP `RunAllTests`：298 passed，0 failed／skipped／not run；包含 alert 专项 28 个执行场景，见[测试摘要](evidence/alert-session-state/tests.txt)；交互证据及范围见[重试报告](evidence/alert-session-state/runtime-retry-2026-10-20/report.md) |

验证环境：本工作区 `ChineseCalendar.xcodeproj`、`ChineseCalendar-iOS`、`chinesedate iPhone 18 Pro Max (885f)`（iOS 27.0），Simulator ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。该测试操作构建了 App 与测试 target；没有单独执行 Release 或真机构建。

`./Scripts/format.sh --check`：0/266 文件需要修改；`./Scripts/lint.sh`：255 文件、0 violations；`git diff --check` 通过。首次测试构建发现新增测试的私有类型别名访问级别不匹配，修正后上述测试与静态检查通过。

### Simulator 交互

2026-10-19 首轮独立验证确认当前代码安装启动、日历切换到设置页，留存了前后截图与 hierarchy。原生会话随后失效，XcodeBuildMCP 备用点击及一次重试虽返回成功，fresh snapshot 和截图均未切换到目标页面，未能进入导航调试页。两个原生会话均已尝试关闭，返回会话已不存在。

首轮按 `device-interaction` 技能的一次重试限制停止扩大排障，alert 场景当时均未验证；详见[首轮历史报告及证据](evidence/alert-session-state/runtime/report.md)。未将工具失败归因为产品缺陷。

2026-10-20 根据用户“再试试”的要求，在同一 Simulator 上重新安装运行后验证以下流程。主代理复核了源码哈希，七个文件均与自动验证记录一致；本轮仅补充交互证据，没有改动产品源码。

| 场景 | 结果 |
| --- | --- |
| 连续两个 alert | 提示 1 关闭后显示提示 2，再关闭后回到设置 |
| Alert 按钮导航 | 关闭后进入历史 Tab（界面标签“朝代”），Push 深度为 1 |
| sheet：取消外部历史跳转 | 业务提示关闭后出现独立离开确认；取消后保留模态 UUID `85B03B39-C9B6-42D5-BF0C-ACA9E2136E69`、Push 深度 0 |
| sheet：批准外部历史跳转 | 业务提示与离开确认依次完成后关闭 sheet，历史 Tab 的 Push 深度由 1 增为 2 |
| full-screen：取消外部历史跳转 | 业务提示关闭后出现独立离开确认；取消后保留模态 UUID `1031610C-1CB0-44AF-9762-74748FFBFB90`、Push 深度 0，截图与 snapshot 已核对 |
| full-screen：批准外部历史跳转 | 业务提示关闭后出现独立离开确认；批准后关闭模态，历史 Tab 的 Push 深度由 2 增为 3，新页面 UUID 为 `599A8D29-2961-46DF-9027-0069051A9A83` |

前四项由原生 Xcode 设备会话操作。全屏取消过程中原生 MCP 返回 `Transport closed`，随后通过固定同一 Simulator 的浏览器镜像完成取消；浏览器失去连接后，以 XcodeBuildMCP 的当前 snapshot 操作完成全屏批准。每项以实际页面回读判断结果；工具返回成功但页面未变的点击未计为通过。截图、hierarchy／snapshot 及资源清理记录见[重试报告](evidence/alert-session-state/runtime-retry-2026-10-20/report.md)。

本轮交互验证了正常点击、提示先后出现及模态关闭后的导航结果，没有模拟耗时异步业务动作，也没有测量 UIKit 动画时长；异步动作处理期间的阻塞契约由状态机测试覆盖。单元测试通过手动推进生命周期事件验证状态与协调，不代替上述真实交互。

### 合并前审查

2026-10-20 按 `review-changes` 工作流完成一次独立生命周期与导航专项审查。审查覆盖两个生产改动文件、相关测试与文档，并沿实际 App 入口、递归呈现宿主、UIKit completion、异步动作和外部导航协调链核对 NAV-03／NAV-04／NAV-05。未发现本次改动引入的可执行缺陷或强制规范违规，没有待修复项。

主代理核对了专项报告与对应调用路径；审查时 63 个工作区快照文件及七个测试绑定源码哈希均匹配。提交时产品代码与测试保持不变，仅补充本审查结论和提交标识。AS-01 至 AS-06 的验证范围保持上文记录；没有将审查、手动推进状态的测试或普通点击流程扩展为长耗时异步动作、竞争压力、后台恢复或真机验证。
