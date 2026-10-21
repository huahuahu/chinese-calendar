# Simulator 代表性交互证据

- 日期：2026-10-22；原生 Xcode MCP，`ChineseCalendar-iOS`，iPhone 18 Pro Max（iOS 27.0），竖屏 440 × 956 pt。
- 运行代码：`76284df6973fb55c9de241398bbf6548ebf4803c`；安装后仅修改测试、格式和文档，后续源码唯一增量为说明性注释。实际测试源码清单见 [source-manifest.json](source-manifest.json)。
- 独立交互代理每次依据 hierarchy hitPoint 操作，并重新捕获确认结果；主 Agent 复核关键截图。完整临时操作报告保留于 `.output/navigation-runtime-device.md`。

| 场景 | 实际操作与结果 | 关键截图 |
| --- | --- | --- |
| Tab 保留与 push/pop | 设置 → 调试操作 → 导航测试 → Push；切日历再切设置，页面 ID 与 push 层数不变；再 push、系统返回后恢复原 ID | [切回设置](01-tab-path-preserved.png) |
| 嵌套模态 | Sheet 打开测试页 → 全屏打开测试页 → 关闭回原 Sheet → 关闭回原父页，ID 和父栈层数保持 | [嵌套全屏](02-sheet-nested-fullscreen.png) |
| 关闭重开 | 再次打开 Sheet 得到新页面 ID、空 path，可以继续交互 | [重新打开](03-sheet-reopened.png) |
| 业务提示队列 | 连续显示两个 Alert → 提示 1 → 好 → 提示 2 → 好；回原 Sheet | [第二个提示](04-alert-queue-second.png) |
| 模拟 Deep Link 取消 | Sheet 滚动至外部链接，模拟打开今年 Deep Link；留在当前页面后保留 Sheet 和滚动位置 | [离开确认](05-deep-link-confirmation.png) |
| alert 期间导航与批准 | Alert 期间请求跳转历史 → 先业务提示 → 好 → 离开确认 → 关闭并前往；关闭后进入根朝代 Tab，模态不再可见 | [批准后目标页](06-approved-cross-tab-navigation.png) |
| 多 Tab 模态 | Sheet 打开主标签页 → 朝代 → 西汉详情 → 设置 → 朝代，仍在西汉详情；返回列表并关闭回原父页 ID | [详情保留](07-modal-tab-detail-preserved.png) |

上述流程通过；所有稳定帧 App 均为 Running，未见崩溃、稳定画面文本重叠或持续空白。确认淡入和关闭中出现过过渡帧，额外捕获后均稳定显示预期界面。交互会话已结束，随后运行自动测试。

未覆盖真机、横屏、iPad/Duo 宽屏两/三栏、拖拽关闭、真实外部 URL/系统 openURL 入口、独立“从 Alert 按钮跳转”按钮及取消后再次批准同一个年份 Deep Link。模拟年份 Deep Link 的取消与历史跳转的批准是两条单独验证的流程，不据此声称真实系统 URL 全链路通过。Context 弱引用释放和同 ID 隔离由自动测试验证，截图不作为内存释放证据。
