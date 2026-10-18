# 单栏实现交付检查

- 日期：2026-10-18。
- 范围：用户要求先合并已有单栏实现；多栏／SplitView 设计暂缓，未纳入提交。
- 基线：`88e3b74ae7bab044389a9a471346e16f9880bd1c`；实现提交：`cfd1372d`。
- 当前 API 与状态归属以 [Core README](../../../Sources/NavigationCore/README.md) 和 [NAV-01–NAV-06](../../Conventions/Navigation.md) 为准。原始方案及 004–011 记录设计演进，不把历史 API 当作当前 API。

## 合并前审查与修正

按 `review-changes` 分为 Core 路由、UI 宿主、App 接入三个独立专项。三个专项均完成源码检查；修正后对受影响路径定向复核，没有剩余已确认缺陷。

| ID | 结论与处理 | 验证 |
| --- | --- | --- |
| routing-001 | 业务 alert 结束后，旧的待确认请求可能继续等模态关闭，并在关闭回调中覆盖较新的请求。新请求现会替代旧的未批准请求。 | 新增参数化回归测试，修正前两个场景失败，修正后通过。 |
| routing-002 | 定向复核发现中间修正不能清除另一条已批准请求。最终条件保留已批准请求，新链接单独确认；取消新链接不会撤销旧的已批准导航。 | 两个额外回归测试覆盖确认 alert 完成窗口、业务 alert 结束后的模态关闭窗口。 |
| UI-001 | 历史详情和资料卡 Preview 缺少新增的非 optional 环境。`SampleNavigationPreview` 复用 sampleData 的 coordinator 与唯一呈现宿主，并提供对应栈。 | 两个 Preview 原生渲染成功；源码复核确认 push 和菜单共用同一 owner。Preview 渲染不代表点击已验证。 |

专项完整报告位于本地 `.output/reviews/20261018-navigation-single-column-merge/`，不纳入产品 diff。这里保留可持续引用的结论和必要证据。

## 自动验证

环境：`ChineseCalendar-iOS`、Simulator `chinesedate iPhone 18 Pro Max (885f)`，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。原生 Xcode MCP 重新构建并运行测试；源码由 [清单及 SHA-256](evidence/merge-single-column/source-manifest.json) 标识。

| 检查 | 结果 |
| --- | --- |
| 初始当前代码测试 | 278 passed，0 failed/skipped/not run；[摘要](evidence/merge-single-column/tests-initial.json)。 |
| 回归复现 | 278 passed、2 failed，失败均为 routing-001 新用例；[实际失败断言](evidence/merge-single-column/tests-regression-before-fix.json)。 |
| 修正后全套测试 | 282 passed，0 failed/skipped/not run；[摘要](evidence/merge-single-column/tests-final.json)。随后仅将同文件的一组测试移入 extension，满足类型长度 lint 限制，产品源码未变。 |
| SwiftFormat / strict lint | 全量通过，261 个格式检查文件、250 个 lint 文件；[格式](evidence/merge-single-column/format-final.txt)、[lint 摘要](evidence/merge-single-column/lint-final.txt)。 |
| 本地化 | 291 项资源通过；[结果](evidence/merge-single-column/localization.txt)。 |
| 数据 schema / seed store 脚本测试 | 通过；[schema](evidence/merge-single-column/schemas.txt)、[脚本测试](evidence/merge-single-column/seed-store-tests.txt)。 |
| 空白检查 | `git diff --check` 通过。 |

本轮测试以确定性的生命周期事件验证状态机，不以其代替 UIKit 动画和实际按钮交互。没有引入数据格式或数据库改动，也未清理已下载数据。

## 交互与交付状态

Simulator 关键交互正在补验，最终状态与证据将追加到本节。历史交互结果仍限定于其记录的源码版本；未完成的验收不标为通过。真机、VoiceOver、真实网络下载及跨进程自动恢复不在本次新增验证范围。
