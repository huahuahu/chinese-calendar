# 月／日选择真实 Simulator 验证

- 日期：2026-10-24；本机时区 Asia/Shanghai。
- 当前验证设备：`Chinese-date Issue 182 (15bc)`，`BB854709-1C84-4E45-A6EB-63A6DD0EFF18`。
- 前两轮使用的旧目标：`chinesedate iPhone 18 Pro Max (885f)`，`16A9CAA7-45CE-46D5-8915-F61531FC617C`。该目标已失效，前两轮材料不属于当前构建的有效行为证据。
- 项目：`/Users/tigerguo/.codex/worktrees/15bc/Chinese-date/ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`。
- App：`com.tiger.suzhou.ChineseCalendar`。
- 交互由独占设备的验证子代理执行，未构建、未运行测试；仅通过明确下载按钮启动可重新下载的完整日期数据，未清空或修改其他数据。

## 工具情况

原生 Xcode `DeviceInteractionSynthesize` 使用主代理提供的 `Calendar Month Day Verification` 返回 `Session not found`。子代理新建 session 后跨 `functions.exec` 调用也得到同一错误；同一次调用内 StartWorkspaceSession + Synthesize 可以捕获设备，但后续会话不能继续。捕获时为 SpringBoard，原已运行 App 不在前台。

按 AGENTS.md 的能力失败回退规则使用 XcodeBuildMCP。先执行 `session_show_defaults`，确认绝对项目路径、scheme、simulatorId 和 simulatorName 均与 `.xcodebuildmcp/config.yaml` 一致；仅临时补充 App bundleId，再 launch 已安装 App。没有切换设备，没有执行 build 或 test。

## 证据有效性更正

主代理后续核对发现，旧 UUID 已不在 XcodeBuildMCP `list_sims` 中，对应 `device.plist` 也不存在；原生 Xcode 已切换到另一台 `iPhone 18 Pro`。因此，前两轮截图与 native 构建／运行的设备目标不一致，不能证明当前版本发生基础库首页错误。旧 framework 时间差只是在错误目标上取得的信息，撤回“旧 UI package 导致当前构建异常”的根因猜测。

主代理新建任务独立 Simulator `BB854709-1C84-4E45-A6EB-63A6DD0EFF18`，更新共享配置并重新选择 native destination。子代理核对新 `.xcodebuildmcp/config.yaml` 后发现自己的 XcodeBuildMCP session defaults 仍指向旧设备，已显式更新为新名称和 UUID；尚未对新设备启动 App 或点击。后续每次交互必须核对工具返回的新 UUID。

以下两轮仅保留为目标失效的工具调查记录，所有当前版本行为结论均不成立；正式验收从新目标重新开始。

## 第一轮：失效旧目标上的捕获（无效行为证据）

1. 21:17 使用 XcodeBuildMCP `launch_app_sim` 启动已安装 App，PID 3904。
2. `snapshot_ui` 和截图均显示整页“需要完整日期数据”，说明为“当前内置数据只有年份和月份。请先下载完整日期数据，再浏览日历。”。
3. 页面只有底部下载按钮与日历／朝代／设置 Tab，没有年月头部、月份条、前后月或今天按钮。因此不能执行基础库浏览验收，未点击下载绕过该问题。
4. 证据：[首页截图](00-initial-base-unavailable.jpg)、[UI hierarchy](00-initial-base-unavailable-hierarchy.json)。可见内容未发现文本截断或重叠，但年月浏览主体缺失。
5. 只读核对旧目标 bundle：主 executable 和 debug dylib 修改时间为 21:09:36；嵌入 framework binary 修改时间为 21:00:57。由于此目标失效且不对应 native 运行目标，该时间差不作为根因证据。
6. 只读查询 bundled SQLite：2026 年存在连续月序 27781–27792，九月为 27789，`isLeapMonth = 0`、`intercalaryMonthNameStyleRawValue = leap`，不缺当前年月份。
7. launch 的 stdout 未发现“无法解析日历选择”或 SwiftData 查询错误；仅有系统 Accessibility 重复类和 NSMapGet 日志。OSLog 文件未给出相关错误。
8. 主代理开始重新核对构建和运行相关测试；验证子代理已停止设备交互，待重新安装后继续。

## 第二轮：构建与捕获目标不一致（无效行为证据）

主代理报告 85 个相关 iOS 测试通过，随后使用原生 `RunProject(attachDebugger: true)` 重新构建安装启动，PID 15605，安装目录已更换。验证子代理仅执行 `snapshot_ui` 与截图，仍看到同样的整页基础数据空态，无年月／月份／今天入口。

旧目标材料：[截图](01-reinstalled-base-unavailable.jpg)、[UI hierarchy](01-reinstalled-base-unavailable-hierarchy.json)。未点击下载。随后确认 native 已切换设备而捕获工具仍用旧 UUID，因此这些材料不能作为重新安装版本的首屏证据，也不能认作代码失败。

## 新独立设备：基础库浏览通过

本轮 native StartWorkspaceSession 明确返回 UUID `BB854709-1C84-4E45-A6EB-63A6DD0EFF18`；hierarchy 显示 App PID 34776。原生 session 后续仍偶发 `Session not found`，交互继续使用已对齐新设备的 XcodeBuildMCP。每次 snapshot 和 tap 返回的 simulatorId／udid 都核对为该 UUID。一次 elementRef 过期后重新 snapshot 再操作，没有复用旧目标坐标。

1. 首页显示“丙午年 九月大／30天 · 戊戌月”，月份条九月蓝色高亮；上个月、下个月和今天均可见。日格局部提示“完整日期数据尚未下载／下载完整日期数据后，可查看本月的每日信息。”，未显示日详情。[截图](02-base-current-month.png)、[native hierarchy](02-base-current-month-hierarchy.txt)。
2. 点击上个月进入“丙午年 八月小／29天 · 丁酉月”，再点击下个月回到九月。操作后等待页面更新再捕获。[前月](03a-base-previous-month-hierarchy.json)、[后月](03b-base-next-month-hierarchy.json)。
3. 点年月标题打开年份选择器，2026 年显示勾选；点 2025 年，选择器自动关闭，页面落在“乙巳年 十二月小／29天 · 己丑月”。[选择器层级](03c-base-year-picker-hierarchy.json)、[选年结果](03-base-selected-2025.jpg)。
4. 点击下个月，跨到“丙午年 正月大／30天 · 庚寅月”；点今天回到丙午年九月。[跨年层级](03e-base-cross-year-hierarchy.json)、[今天层级](03f-base-return-today-hierarchy.json)。
5. 点击月份条“十月大”，显示“丙午年 十月大／30天 · 己亥月”；以此非当前月作为换库恢复检查位置。[下载前截图](04-base-before-download-month10.jpg)、[层级](04-base-before-download-month10-hierarchy.json)。
6. 点击底部下载，进入第 1/5 步准备下载，随后第 2/5 步下载文件；进度首次观测为 1%。仍停在丙午年十月，未自动跳回九月。

可见年月标题、局部提示和年份选择器文字没有重叠或不可读截断。月份条两侧部分项目位于横向滚动视口边界，是可滚动内容的边缘显示。

## 下载观察与本轮停止边界

下载从 1% 持续推进至 3%、5%，离开详情回到日历后为 **第 2/5 步：下载文件，7%**。下载详情显示准备下载已完成，文件下载进行中，校验文件／安装数据／完成均等待开始；没有显示网络错误。详情中只提供关闭按钮，没有可见取消下载入口，因此按主代理指示关闭详情并停在日历，未通过其他手段删除临时下载或中断进程。

[下载详情截图](05-download-details.jpg)、[详情层级](05-download-details-hierarchy.json)、[最终日历截图](06-calendar-month10-during-download.jpg)、[最终层级](06-calendar-month10-during-download-hierarchy.json) 显示选中位置仍为“丙午年 十月大／30天 · 己亥月”，没有被原始首页九月落点覆盖。新设备、下载提示、进度与月份条显示正常，截图未发现文字重叠或不可读截断。

主代理要求不继续等待约 200 MB 文件传输。因本轮网络传输耗时，未到达安装完成，**下载完成后的 UI 升级、完整库具体日选择、清空后的 UI 降级未验证**。已有 Feature 换库回归测试通过属于独立自动测试证据，不能代替这三项实际交互。

设备已交回主代理进行测试和快照工作。最后停留在基础库丙午年十月的日历页，下载 7%；未为了最终状态再改回今天。native session key 为 `Issue 182 Fresh Device Verification`，此前最后一次调用已报 `Session not found`；验证子代理未调用 EndSession，交由主代理处理。

## 当前验收状态

| 场景 | 状态 | 说明 |
| --- | --- | --- |
| base 首页显示当前年月和局部下载提示 | 通过 | 新独立设备显示丙午年九月和局部提示 |
| base 前后月、月份条、年份选择器、跨年、今天 | 通过 | 九月／八月、2025 十二月到 2026 正月、今天回九月、月份条选十月 |
| 下载进行期间保持非当前月 | 通过 | 丙午年十月下载推进至 7%，未跳回首页九月 |
| 安装 full 后保留同月并显示日格及日详情 | 未验证 | 本轮网络传输耗时，停止于第 2/5 步 7% |
| full 选具体日后清空为 base，保留同月 | 未验证 | 未完成安装，未操作清空；Feature 回归测试不代替 UI 验证 |
| 今天返回 base 当前月 | 通过 | 下载前已从正月通过今天返回九月；最终按主代理要求留在下载中的十月 |
