# 改用库内置 SwiftUI 截图策略

- 日期：2026-10-24
- 关联：[原方案](000-plan.md)、[首次实现结果](001-result.md)、[PR #173](https://github.com/huahuahu/chinese-calendar/pull/173)
- 状态：实现及本地验证完成，远程 CI 未运行

## 背景与方案

PR 和合并后的 main CI 都在 iPhone 截图组出现 SwiftUI Observation 布局反馈循环，随后在自定义窗口清理时报告 `InvalidTransition ... failed(deinit)`。本地重跑未复现，因此尚不能确定具体触发机制。

用户要求直接使用 SnapshotTesting package 自带的 SwiftUI 截图能力，并明确选择默认的 `drawHierarchyInKeyWindow: false`，主要检查内容、间距、换行和页面布局。删除自定义 `SnapshotRenderer`、窗口子类、强制布局和连续帧轮询；直接把注入示例数据与固定环境的 SwiftUI View 传入 `.image(drawHierarchyInKeyWindow: false, layout:traits:)`，由 SnapshotTesting 1.19.7 管理承载与截图。保留 23 个场景、比较精度和显式录制机制，增加场景级 XCTest activity，便于定位后续失败。

使用库内置 iPhone 13（390×844）和 iPad Pro 12.9 横屏（1366×1024）布局、1× 输出。库创建独立测试窗口，按 device config 提供 safe area，以 layer rendering 截图；这些截图用于布局回归，不保证系统玻璃材质与前台窗口一致。先比较原基准并检查实际图片，再按已确认的渲染方式变化更新必要基准，不以放宽阈值处理失败。

## 验收

- 测试源码不再自行创建 UIHostingController、UIWindow 或调用 drawHierarchy。
- 相同 23 个场景有完整内容，原生策略生成的差异经过检查。
- 比较模式通过；缺失或不匹配基准仍会失败。
- 格式、strict lint 通过，文档反映当前实现及验证边界。

## 结果

已删除 111 行自定义 renderer，测试直接使用库原生 SwiftUI `.image`，显式设置 `drawHierarchyInKeyWindow: false`。sample data、23 个场景、生产页面和比较阈值保持原有范围。

23 张 PNG 已按原生离屏策略重新录制并逐组检查。变化包括系统材质不再经过真实窗口合成、库设备安全区下的页面位置、年份选择器初始视口及导航栏呈现。日历内容、历史三栏和已选中皇帝列表、空态、设置、深色及大字号场景均有实际内容。视口大小仍为 390×844 或 1366×1024，输出为 1×；基准用于内容与布局回归，不作为玻璃材质或交互效果的验收。

验证基于 `242ad28214bdbe501baf21500039775e0e524b8b` 后的未提交工作区，源码与基准摘要见 [native-source-state.json](evidence/native-source-state.json)。共享 Simulator 为 iOS 27.0 / arm64 的 `chinesedate iPhone 18 Pro Max (885f)`，Xcode 27.1，使用原生 Xcode MCP。

| 检查 | 结果 |
| --- | --- |
| 完整截图比较 | 两轮均 4/4 测试组通过，共 23 张图；最后一轮在负向验证恢复后执行 |
| 不匹配基准 | 给深色日历基准添加红色块后，测试报告不匹配 |
| 缺失基准 | 移走大字号基准后，测试报告缺图，且未自动生成基准 |
| 恢复 | 全部 23 张 PNG 的 SHA-256 与录制后摘要一致 |
| 渲染日志 | 两轮通过日志未出现 Observation feedback loop、InvalidTransition 或 appearance 不平衡 |
| 格式与 strict lint | 0/356 文件需格式化；343 文件 0 violations |

精简测试结果见 [native-swiftui-validation.json](evidence/native-swiftui-validation.json)。本次未修改生产代码，未重新运行普通业务测试、远程 CI、交互测试或真机测试；本地通过不能证明远程 CI 已恢复。未运行专项 code review。
