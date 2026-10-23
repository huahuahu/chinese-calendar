# Issue #165 Simulator 交互记录

- 日期：2026-10-23 至 2026-10-24（Asia/Shanghai）。
- 工程：首轮 `workspace-kpQmEW1QLS`，第二轮 `workspace-wBdyYlXQqm`；scheme 均为 `ChineseCalendar-iOS`。
- Simulator：`chinesedate iPhone 18 Pro Max (885f)`，`16A9CAA7-45CE-46D5-8915-F61531FC617C`。
- App：`com.tiger.suzhou.ChineseCalendar`，首轮 PID `5405`。
- 工具：native Xcode MCP；首轮 session `Issue 165 Presentation Ownership`，第二轮 `Issue 165 Year Picker Validation`。点击依据最新 UI hierarchy；动画早期截图与 hierarchy 不一致时重新捕获后判断。
- 代码快照与最终构建结果由主结果文档记录；本文件只报告实际交互。

## 首轮已完成

| 场景 | 实际观察 | 证据 |
| --- | --- | --- |
| 基础数据状态 | 日历显示“需要完整日期数据”，内置数据只有年份和月份，没有选年入口；此轮不能验证年份选择。 | [01 hierarchy](01-base-store-year-picker-unavailable.txt)、[截图](01-base-store-year-picker-unavailable.png) |
| Sheet 交互撤销 | 在父 sheet 顶部下拉后回拖，取消关闭；页面 ID 保持 `7C457E7A-414B-4219-9E12-4C76095443C1`。 | [02a 原页面](02a-parent-sheet-before.txt)、[02b 撤销后](02b-sheet-gesture-cancelled.txt) |
| 子 fullScreen 关闭 | 从父 sheet 打开 fullScreen，子页面 ID 为 `1E241C75-3023-48E8-B488-99F9B6912AB0`；点击子关闭后返回原父页面，父 ID 不变。 | [02c 子页面](02c-nested-fullscreen.txt)、[截图](02c-nested-fullscreen.png)、[02d 返回父页](02d-parent-after-child-close.txt) |
| 下载演示共享状态 | 选择下载 50%，切到“切换检查”Tab 后附件仍为 50%；附件打开子详情显示文件已下载 50%。 | [03a 场景](03a-download-preview-50.txt)、[03b 第二 Tab](03b-download-second-tab.txt)、[03c 子详情](03c-download-child-detail.txt)、[截图](03c-download-child-detail.png) |
| 下载演示子关闭与重开 | 子详情关闭后父附件仍为 50%，切回场景 Tab 后 50% 仍 Selected；整个演示关闭后重开，恢复“准备”Selected、第 1/5 步。 | [03d 子关闭](03d-child-closed-parent-preserved.txt)、[03e Tab 返回](03e-stage-retained-after-return.txt)、[03f 整流程重开](03f-reopen-new-preview-state.txt) |
| 连续 alert | 业务提示 1 关闭后才出现业务提示 2，未观察到重叠。 | [04a 第一条](04a-first-alert.txt)、[04b 第二条](04b-second-alert.txt) |
| Alert 期间请求导航：取消 | 业务提示 1 关闭后出现“离开当前页面？”确认；点击“留在当前页面”返回原 sheet。 | [04c 前置提示](04c-alert-before-navigation.txt)、[04d 离开确认](04d-leave-confirmation-after-alert.txt)、[截图](04d-leave-confirmation-after-alert.png)、[04e 取消](04e-cancel-retains-sheet.txt) |
| Alert 期间请求导航：批准 | 再次触发后选择“关闭并前往”，模态消失，根朝代 Tab Selected，进入 Push 页数 1 的导航测试页。 | [04f 到达历史](04f-approve-arrives-history.txt) |
| App 内模拟 Deep Link | 新开 sheet 后点击“模拟打开今年的 Deep Link”，确认文案包含公元 2026 年；批准后模态消失，日历 Tab Selected，进入带返回按钮的日历目标页。因基础数据缺失，该页仍提示需要完整日期数据。 | [04g 确认](04g-simulated-deeplink-confirmation.txt)、[04h 到达](04h-simulated-deeplink-arrived.txt) |
| DEBUG 三栏 push | 在混合 Tab 中进入三栏，依次选择分类一、对象一、下一层详情；到达“子详情第 1 层”，当前详情对象一，Push 页数 1。 | [05a 三栏详情](05a-three-column-push.txt) |

## 首轮停止点

三栏详情切到普通栈 Tab 后，续接调用返回 `Session not found`；没有把失败的切回调用当作交互成功。主流程随后停止 App，准备本地完整数据 fixture 和新 session。

## 第二轮已完成

第二轮由主流程在 App 停止时准备本地完整数据 fixture，再 InstallAndRun。fixture 校验、884256 条日记录及原 store 备份由主流程记录；该准备过程不计作网络下载或运行中 store 替换。

| 场景 | 实际观察 | 证据 |
| --- | --- | --- |
| 根日历选年与重开 | 根日历初始丙午年 2026；选择器自动定位当前年。选择 2025 后返回乙巳年十二月，月格与月份条更新；重开后 2025 居中且 Selected。 | [06a 当前年](06a-root-picker-current-year.txt)、[06b 选择 2025](06b-root-selected-2025.txt)、[06c 重开](06c-root-picker-reopened-2025.txt) |
| Picker 手势撤销与完整关闭 | 顶部下拉后回拖，选择器保留且 2025 仍 Selected；再次完整下拉，返回根日历；重开仍选中 2025，随后按钮关闭。 | [06d 撤销](06d-picker-gesture-cancelled.txt)、[06e 完整下滑](06e-picker-swipe-dismissed.txt)、[06f 下滑后重开](06f-picker-reopened-after-swipe.txt)、[截图](06f-picker-reopened-after-swipe.png) |
| 第二日历来源与嵌套 picker | 设置 → Sheet 打开主标签页 → 日历：嵌套日历初始 2026；其 picker 也选中 2026。选择 2024 后仅嵌套日历更新为甲辰年十二月；重开其 picker，2024 Selected。 | [07a 嵌套来源](07a-nested-calendar-starts-2026.txt)、[07b 初始 picker](07b-nested-picker-current-2026.txt)、[07c 选择 2024](07c-nested-selected-2024.txt)、[07d 重开](07d-nested-picker-reopened-2024.txt)、[截图](07d-nested-picker-reopened-2024.png) |
| 年份列表滚动与来源隔离 | 嵌套 picker 手动向下拖动列表，可见年份范围移动，2024 的选中标记保持；关闭 picker 和整层主标签页后，根日历仍为乙巳年十二月 2025，没有被嵌套选择改写。 | [07e 列表滚动](07e-picker-manual-scroll.txt)、[07f 根来源保持](07f-root-still-2025-after-nested.txt) |
| DEBUG 三栏状态保持 | 新混合 Tab 中选择分类一、对象一并 push 第 1 层；切普通栈再回三栏，仍为对象一、Push 页数 1。横屏 956×440 时对象列表与详情同时可见，随后回竖屏仍为子详情第 1 层。 | [08a push](08a-three-column-push-new-session.txt)、[08b Tab 返回](08b-three-column-tab-return.txt)、[08c 横屏](08c-three-column-landscape.txt)、[截图](08c-three-column-landscape.png)、[08d 竖屏返回](08d-three-column-portrait-return.txt) |
| 正式历史容器状态保持 | 朝代 → 秦 → 帝王，显示三位帝王列表；切设置再回朝代仍在该页面。横屏显示左侧秦栏目“帝王”选中、右侧帝王列表；回竖屏仍在帝王页。帝王行是当前页面的静态内容，本轮没有进入独立皇帝详情。 | [09a 帝王列表](09a-history-emperor-list.txt)、[09b Tab 返回](09b-history-tab-return.txt)、[09c 横屏](09c-history-landscape.txt)、[截图](09c-history-landscape.png)、[09d 竖屏返回](09d-history-portrait-return.txt) |
| 实际清空与运行中 store 替换 | 设置中确认清空后显示“已清空”，说明已恢复内置基础数据；日历更新为“需要完整日期数据”，历史的秦／帝王页继续可用。 | [10a 成功提示](10a-clear-store-success.txt)、[截图](10a-clear-store-success.png)、[10b 清空后日历](10b-calendar-after-clear.txt)、[10c 清空后历史](10c-history-after-clear.txt) |
| 正式下载详情随进度结束退出 | 启动 DEBUG“模拟完整数据下载”，点击正式底部进度附件进入详情，hierarchy 捕获下载文件 60% 进行中；没有点击详情关闭按钮。模拟结束清除进度后，详情自动消失并回到根设置页，数据仍为基础数据。 | [11a 进行中详情](11a-simulated-download-detail-active.txt)、[截图](11a-simulated-download-detail-active.png)、[11b 自动退出](11b-progress-cleared-detail-auto-dismissed.txt) |

第二轮停止在根设置页、基础数据、无活动模态。交互代理没有结束 session，交由主流程结束并运行最终测试。共保留 10 张关键截图，其余以 hierarchy 记录。

## 最终证据边界

- App 内模拟 Deep Link 不能替代系统热 URL；后者由独立 XCUITest 记录。
- 完成了实际清空造成的运行中 store 替换，但没有在活动 picker 尚未结束时执行替换；旧结果失效仍需对应集成测试证明。
- 模拟下载经过正式进度附件与详情路径，但不访问网络、不写下载文件、不安装数据库；没有真实网络下载证据。进度截图和 hierarchy 在相邻帧采集，百分比略有差异，均处于下载进行中。
- 覆盖 DEBUG 三栏、正式历史容器的 Tab 和横竖切换；没有穷举单独两栏、所有宽度和所有历史目标。
- 年份选择的界面过渡、自动定位、手动滚动和最终月格均观察到；没有视频或帧率数据，不据截图声明动画性能结论。
- 页面状态与页面 ID 只能证明可见交互结果；资源释放、结束回调次数及父子完成顺序须结合自动测试的 weak probe 和合同断言。
- 已完成调用返回的 App 状态均为 `Running`；未观察到稳定的功能或布局异常。首轮 session 失效属于工具状态，未据此报告 App 崩溃。
