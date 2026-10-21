# 栈导航与呈现环境分离

- 日期：2026-10-13；状态：实现完成，Simulator 交互部分验证。
- 用户确认：NavigationContext 不公开 presentation，也不转发 present/dismiss；页面从呈现环境直接发起模态操作。
- 承接 [008](008-presentation-layers.md)，替代其中“栈上下文保留 present/dismiss 便利入口”的决定。
- 后续内部依赖分离见 [010](010-independent-stack-state.md)：栈上下文改为独立栈状态与窄访问约束，下文保留本阶段 Router／层弱引用的实现与证据。

## 方案

1. NavigationContext 只暴露栈身份、有效性、path、push/pop，通过 Router 和原始层的弱引用访问状态，不依赖 NavigationPresentationContext。
2. 页面分别读取 navigation 与 presentation 环境。模态状态、dismiss、isPresented 和确认仍归 `NavigationPresentationContext`；业务 coordinator 接收发起页面的 `NavigationPresentationContext`。
3. NavigationScopeView 从所属层的呈现环境取得带发起栈身份的呈现入口并注入后代。不同栈的入口共享原始层状态，但 present 会检查发起栈是否仍选中；层级控件继续使用不绑定栈的入口。入口身份不进入快照。
4. 导航和呈现均通过 Router 检查层对象有效性及确认／根关闭事务。保留旧上下文失效、取消不改变状态、实际关闭完成后再跳转等语义。
5. 同步 App、测试、Core README 和导航规范，保留此前工作区改动。

## 验收

- Core 栈 API 和 App 调用点均不再通过 navigation 访问呈现能力。
- 多 Tab 路径隔离且共享呈现状态；后台栈无法发起呈现；无导航栈内容仍可直接 present。
- 回归嵌套呈现、旧上下文失效、快照重建、确认取消及关闭完成时序。
- 原生 Xcode 构建测试、格式与 lint；实际交互与自动测试分别记录结果。

## 结果

已完成 Core、App 调用点、测试与文档迁移。`NavigationContext` 不再引用 `NavigationPresentationContext`；两种上下文通过 Router 共同校验原层身份及导航事务。`NavigationScopeView` 分别注入栈上下文和带来源栈身份的呈现入口。来源栈只影响操作许可，不增加导航状态或快照字段。

年份选择器与设置 Debug 下载演示向 coordinator 传入页面的 `NavigationPresentationContext`，呈现被拒绝时释放刚创建的业务会话。下载演示容器及关闭按钮直接读取呈现环境。页面的 push/pop 仍读取导航环境。

- 代码状态：`codex/issue-145-unified-navigation`，HEAD `88e3b74ae7bab044389a9a471346e16f9880bd1c` 加未提交工作区；本次检查对应 [源码 SHA-256](evidence/context-separation/source-sha256.txt)，不以 HEAD 代表全部实现。
- 环境：`ChineseCalendar-iOS`，`chinesedate iPhone 18 Pro Max (885f)`，Simulator ID `16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0。

| 验收项 | 状态 | 证据与边界 |
| --- | --- | --- |
| 栈与呈现 API 独立 | 已验证 | 栈上下文仅有 id、isActive、path、push/pop；App 页面按需分别读取两个环境，Core README 同步接入方式 |
| 来源栈保护与共享状态 | 已验证 | 自动测试覆盖多个 Tab 独立 path、共享呈现、后台 Tab 拒绝 present，及被拒绝的 Debug 呈现不残留业务会话 |
| 层生命周期与请求事务 | 已验证 | 自动测试覆盖嵌套模态、同 ID 恢复后的旧上下文失效、快照往返、取消保留状态、等待根实际关闭完成；新增测试证明两种上下文均不延长 Router 生命周期 |
| Xcode 构建与测试 | 已验证 | 原生 `RunAllTests` 构建并通过 257 项，0 failed/skipped/not-run；见 [测试结果](evidence/context-separation/tests.txt) |
| 静态检查 | 已验证 | `./Scripts/lint.sh` 为 0 violations；`./Scripts/format.sh --check` 为 0 files require formatting；见 [lint](evidence/context-separation/lint.txt)、[format](evidence/context-separation/format.txt) |
| Simulator 实际交互 | 部分验证 | 原生 Xcode 安装运行当前版本，设置 Debug 菜单连续 push 两页后 pop，恢复原页面 UUID、深度 1 及设置 Tab；sheet hierarchy 已出现模态作用域和独立深度 0。见 [首次 push](evidence/context-separation/runtime/push-hierarchy.txt)、[第二次 push](evidence/context-separation/runtime/push2-hierarchy.txt)、[pop 后](evidence/context-separation/runtime/pop-hierarchy.txt)、[sheet](evidence/context-separation/runtime/sheet-hierarchy.txt) |

原生交互会话随后连续返回 `Session not found`，重建会话后的 `InstallAndRun` 也返回 `Session with that key doesn't exist`。本轮尚未完成完整嵌套 sheet/full-screen、模态内 push 与 Deep Link 取消／批准的真实交互，也未重测下载预览多 Tab 和年份选择器；自动测试通过不代表这些交互已通过。已保存的 [push 截图](evidence/context-separation/runtime/push-screenshot.png) 与 [pop 截图](evidence/context-separation/runtime/pop-screenshot.png) 未见明显布局异常；sheet 首次采集仍在转场，不能作为稳定视觉验收。

降级 XcodeBuildMCP 后，默认配置核对一致，UI 快照和截图成功但显示 Simulator 主屏幕。App 图标点击因 `SNAPSHOT_EXPIRED` 未执行，刷新快照后结束本轮验证；这不证明 App 崩溃，也不能作为嵌套流程的验证证据。两个已知原生会话均已尝试 `EndSession`，返回会话已不存在，无已知待清理会话。已采集到 sheet 开始呈现的日志没有 crash/fatal 或 NavigationCore 错误，含 Simulator 系统诊断，不能据此宣称后续运行无异常。

本轮未单独运行 Release 构建、Preview 或真机验证；没有执行独立代码 review，亦未提交或推送工作区改动。
