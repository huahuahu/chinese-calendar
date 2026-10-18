# 呈现层与多栈：本轮 Simulator 验证

日期：2026-10-11，22:26–22:30。设备为共享配置的 `chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0，UUID `16A9CAA7-45CE-46D5-8915-F61531FC617C`；项目为 d18d worktree，scheme `ChineseCalendar-iOS`，Debug，竖屏。

所有截图均来自本轮最终源码的原生 `DeviceInteractionInstallAndRun` 安装版本。源码未插入验证分支，未清空数据、模拟真实下载或改动数据库。完整原始文件位置和工具结果保存在 [verification.json](verification.json)，对应源码见 [source-sha256.txt](source-sha256.txt)。

## 通过的场景

| 场景 | 实际结果 | 截图及同名 hierarchy |
| --- | --- | --- |
| 根设置入口 | 设置可打开调试菜单；页面仍显示已安装完整日期数据 | [01](01-settings.png) |
| 多 Tab full-screen | 打开下载布局预览，选择下载 50%，切换到“切换检查”；底部进度保持 50% | [02](02-modal-first-tab-50.png)、[03](03-modal-second-tab.png) |
| 同层共享子模态 | 在第二个 Tab 点击底部附件打开 sheet；子页显示 50%，只有一套导航栏 | [04](04-child-sheet.png) |
| 子层关闭与父层保留 | 点击子页关闭，回到仍选中的第二个 Tab，保持 50%；再切换回第一 Tab | [05](05-child-closed.png)、[06](06-return-first-tab.png) |
| 父层关闭 | 点击父模态导航栏的完成，回到设置，完整日期数据保持 | [07](07-parent-closed.png) |
| 根栈 Push/Pop | 设置 Push 页数 1→2→1；Pop 后回到同一个页面 ID `2754135D-930D-4B77-A72B-D433595F1699` | [08](08-tab-push.png)、[09](09-tab-push-again.png)、[10](10-tab-pop.png) |
| 嵌套 sheet/full-screen | sheet 上打开 full-screen；关闭子全屏后返回同一 sheet ID `FEECBA92-2D52-47DF-86B5-B788A48F7E92` | [11](11-parent-sheet.png)、[12](12-child-fullscreen.png)、[13](13-child-fullscreen-closed.png) |
| 模态栈 Push 与取消 Deep Link | 嵌套 full-screen 内 Push 后页数为 1；确认提示出现在最上层。取消后 ID `60EEB365-13F1-40B4-9C13-B1DCF8301321` 和页数 1 保持 | [14](14-modal-push.png)、[15](15-leave-confirmation.png)、[16](16-cancel-preserves-page.png) |
| 批准 Deep Link | sheet→full-screen 中触发今年链接并批准。根关闭转场结束后，日历 Tab 选中，出现 2026 日历目标和返回按钮，无残留模态 | [17](17-approve-confirmation.png)、[18](18-approved-calendar.png) |

业务页面使用正式 `NavigationScopeView`／`navigationPresentations` 宿主。下载预览使用其固定阶段，不会执行下载。每个动作前读取最新 hierarchy 的 hitPoint；操作后读取新的 hierarchy，并检查关键截图的页面、导航栏、Tab、进度和页面 ID。

## 工具与证据边界

最初独立原生 session 在跨调用期间报告 `Session not found`；备用 XcodeBuildMCP 出现 `SNAPSHOT_EXPIRED`，刷新并点击后仍返回旧 SpringBoard 快照，未将动作成功返回当作 UI 通过证据。随后使用连续的原生短会话，读取最新 hierarchy、执行下一步并立即采集，完整通过上述场景。全部自建 session 都已关闭，没有使用或操作父对话的设备 Agent。

菜单行外层的 hitPoint 首次未打开菜单；读取嵌套真实控件后点击文字对应 hitPoint 成功，未修改产品 UI。首次批准后的抓图处于整树关闭转场，未直接判失败或成功；补验在转场结束后再次采集，确认目标落地，见 18。

本轮没有重跑连续外部 URL 替换、真实系统 URL 打开、交互式下滑关闭、跨 Tab 外部请求、横屏、其他设备／OS、VoiceOver、Release 入口运行时可见性或真机。多 Tab 模态各自的 Push path 隔离及快照恢复由自动测试验证，当前演示 UI 没有为每个 Tab 增加新的 Push 控件。旧阶段报告不代替本轮这些未覆盖项。
