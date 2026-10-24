# 主标签页拥有下载附件

- 日期：2026-10-24
- 关联：[根宿主方案](000-plan.md)、[统一页面构建与共享环境](002-unified-destination-builder.md)
- 状态：实现完成；定向自动验证通过，模态内进度文字更新尚缺交互证据

## 目标与方案

用户确认：底部下载状态栏属于拥有 TabView 的页面，由页面读取环境中的业务状态并决定展示，不应作为导航宿主的参数层层转发。

`CalendarHomeTabView` 读取已有的可选 `ChineseCalendarStoreCoordinator` 环境，在数据就绪时优先显示下载进度，否则在允许下载时显示下载提示。显隐直接驱动现有 `calendarTabViewBottomAccessory(isEnabled:)`，不另外保存 Boolean，也不新增环境 key、View builder 或状态适配对象。下载仍由用户按钮触发。

删除 `ChineseCalendarRootView`、`CalendarHomeView`、`CalendarNavigationHost`、`CalendarNavigationConfiguration` 和 `CalendarDestinationView` 的附件泛型、闭包和转发；下载提示抽为独立 View。`CalendarHomeView` 的公开自定义附件初始化接口随之移除；仓库内调用均使用无参默认形式，保留原有无参／settings coordinator 和已弃用的日期初始化入口。

保留 `CalendarHomeCoordinator.downloadDetails`、Host 的进度消失监听与下载错误协调。附件从实际所在层打开详情，根与模态共用同一展示规则；不修改 NavigationCore、宿主身份或 store 内容重建边界。

依据：[SwiftUI 规范](../../Conventions/SwiftUI.md)、[导航规范 NAV-02／NAV-03／NAV-06](../../Conventions/Navigation.md)。

## 验收

| ID | 场景与预期行为 | 验证方式 |
| --- | --- | --- |
| AC-01 | 导航 Host、Configuration、DestinationView 无附件泛型／参数；页面从已有环境读取状态 | 源码、构建 |
| AC-02 | 未就绪或无 coordinator 时隐藏；就绪时进度优先，允许下载时显示提示，否则隐藏 | 源码、针对性测试 |
| AC-03 | 已打开的 sheet/fullScreen 主标签页实时显示、更新并隐藏下载附件，模态身份不变且不误发关闭回调 | App-hosted 集成测试 |
| AC-04 | 详情继续从附件所在层打开，进度消失只关闭对应详情；共享 store 环境和宿主身份保持 | 现有针对性回归测试 |
| AC-05 | App／测试编译、格式、严格 lint 通过 | 原生 Xcode MCP、仓库检查脚本 |

## 实施与验证结果

验证发生在基于 `eaa09912ab77817f688f5e5dde1ba3f00133d599` 的提交前工作区。修改的 11 个 Swift 文件及 SHA-256、最终测试列表见 [verification.json](evidence/bottom-accessory/verification.json)。未修改 NavigationCore 或生成的 Xcode 项目。

`CalendarHomeTabView` 直接读取 store 环境并控制附件，下载提示独立为 `FullStoreDownloadBanner`。Host 仍负责稳定的导航协调和业务环境注入。没有新增共享状态、环境 key 或 View builder 配置。

验证使用原生 Xcode MCP，`ChineseCalendar.xcodeproj` / `ChineseCalendar-iOS`，共享配置的 `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0）。

| 验收项 | 状态 | 实际证据与边界 |
| --- | --- | --- |
| AC-01 | 已验证 | 源码无旧附件泛型／转发参数，App 构建成功 |
| AC-02 | 源码已验证；部分交互已验证 | 未就绪／无 coordinator 的 guard 及 `.full` 判定保留。根页面实测下载提示切到模拟进度、完成后恢复提示；无下载配置的模态测试验证隐藏→显示→隐藏。未实际安装完整数据库 |
| AC-03 | 部分已验证 | sheet/fullScreen 两例通过：原生附件进入／离开窗口、进度变化期间附件可见、模态 controller 身份不变，附件消失不触发 onDismiss，真正关闭恰好回调一次。模态中的进度文字更新尚未取得交互证据 |
| AC-04 | 已验证（源码、回归与根页面交互） | 详情定点关闭、未呈现请求取消、store 环境更新与身份保持测试通过；根页面点击附件打开详情、完成后自动关闭，设置父页面及 Tab 选择保留。未手动操作模态主标签页中的详情按钮 |
| AC-05 | 已验证 | 最后一轮 RunSomeTests 为 22 通过、0 失败／跳过／未运行；Swift format 0/353 需修改，strict lint 340 文件 0 violations，本地化 337 项及 diff 检查通过 |

根页面 Simulator 交互只使用设置中的 DEBUG 模拟下载，不访问真实下载网络或替换数据库。截图观察到进度 10% → 34%，详情打开时 48%；AX 因依次采集分别为 12%、36%、52%。完成后返回设置页面，底部恢复下载提示。长期保留的语义证据见 [运行层级摘录](evidence/bottom-accessory/runtime-hierarchy.txt)。

### 测试方式调整与剩余边界

首轮定向测试为 21 通过、2 失败；失败发生在新增测试尝试从 SwiftUI 附件读取 AX 值时。诊断确认两种模态均已有可见的原生附件，大小为 398 × 48，挂在真实窗口中，但公开 `accessibilityElements`、动态容器枚举及补充的 `automationElements` 均返回空值。该读取方式不能作为 App-hosted 测试中的可靠内容探针。

最终测试保留真实 UIKit 附件显隐和模态生命周期断言，删除不可靠的 AX 读取。store 的进度仅用于控制测试阶段，不当作界面文字更新的证据；根页面文字与进度条更新由上述实际交互验证，AC-03 的模态文字部分继续标为未验证，未修改验收要求。

本轮未运行完整测试套件、iOS 26.0 兼容分支交互、真机、CI 或专项 review。以上为提交前的本地验证记录，CI 状态以后续 PR 为准。
