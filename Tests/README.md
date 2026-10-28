# 测试

跨模块测试与截图基准放在本目录。普通业务测试仍使用 `./Scripts/test.sh`；截图测试有独立的环境约束和入口。

## 当前界面截图基准

`Tests/Snapshots` 中的 App 承载测试将 SwiftUI View 直接传给 Point-Free SnapshotTesting **1.19.7** 的 `.image(layout:traits:)` 策略，使用默认的 `drawHierarchyInKeyWindow: false`。截图关注页面内容、间距、换行和布局。基准 PNG 保存在 `Tests/Snapshots/__Snapshots__`，随代码提交。测试复用项目内存示例数据，固定日期、简体中文、上海时区、外观和字号。

设备布局使用库内置的 `.device(config: .iPhone13)` 和 `.device(config: .iPadPro12_9)`，分别提供 390 × 844 pt 的 iPhone 视口和 1366 × 1024 pt 的 iPad 横屏视口，并通过额外 traits 固定 1× 输出比例。库为离屏截图创建独立窗口，窗口安全区、尺寸和设备 traits 跟随对应的设备布局配置。宽屏场景因此使用 iPad 配置进行布局，承载测试的 Simulator 始终使用下表中的 iPhone。

| 项目 | 基准环境 |
| --- | --- |
| Xcode | 27.2，当前迁移验证使用 RC build 27B48 |
| iPhoneSimulator SDK | 27.2 |
| Simulator runtime | iOS 27.2 |
| Simulator 机型 | iPhone 18 Pro Max，允许自定义设备名称 |
| Mac / 测试架构 | arm64 |
| 测试 target | `ChineseCalendarSnapshotTests` |
| 比较 scheme | `ChineseCalendarSnapshots` |
| 录制 scheme | `ChineseCalendarSnapshots-Record`，设置 `SNAPSHOT_RECORD=1` |

### 首批覆盖范围

共 23 张 PNG，由 4 个 XCTest 测试分组执行：

| 组 | 数量 | 场景 |
| --- | --- | --- |
| iPhone 浅色 | 16 | 现代日历、公元前、公元后、月内纪元边界、后九月、无日期、未下载完整日期、年份选择器、历史时间线、选中皇帝列表、空历史、朝代详情、朝代起讫、皇帝详情、年号详情、设置启动状态 |
| iPad 横屏 | 4 | 现代日历、历史默认三栏、历史已选中三栏、朝代详情 |
| 深色 | 2 | 现代日历、皇帝详情 |
| 辅助功能最大字号 | 1 | 现代日历 |

库负责创建 SwiftUI hosting controller 和独立窗口、配对执行 appearance 生命周期、布局，并通过 `view.layer.render(in:)` 绘制和清理宿主。测试代码不再自行管理 controller/window，不进行连续帧轮询或手工 PNG 解码归一化；截图时机和图像比较采用库原生策略。比较阈值保持 `precision: 1`、`perceptualPrecision: 0.99`：每个像素都参与比较，只允许很小的感知色差，不忽略指定区域，也不容忍一定比例的任意错图。原生策略迁移及基准验证记录见 [后续任务记录](../Docs/Tasks/task-2026-10-24-ui-snapshots/002-native-swiftui-strategy.md)。

当前覆盖日历页面内容；完整 `CalendarHomeView` 内部仍会读取真实“今天”，尚未纳入固定日期基准。设置只覆盖未启动数据库准备的 `.starting` 状态。离屏 layer rendering 不保证真实屏幕上的模糊、玻璃等系统材质效果。滚动页面固定初始视口，截图不表示已经覆盖视口外全部内容，也不证明交互或辅助功能布局符合预期。

### 比较已有基准

在仓库根目录执行：

```bash
./Scripts/test_snapshots.sh
```

脚本会严格检查工具链、SDK、runtime、机型和架构。设备选择按以下顺序进行：

1. 显式的 `SNAPSHOT_SIMULATOR_ID`；CI 传入本任务创建的 UUID，也接受 `CHINESE_CALENDAR_SIMULATOR_ID`。
2. 没有显式 ID 的本地运行使用分配器返回的 `.xcodebuildmcp/config.yaml` 中的 `sessionDefaults.simulatorId`；CI 不读取个人配置。

CI 缺少任务 UUID 时明确失败，不借用已有设备，也不在截图步骤内创建另一台。独立实验按[任务设备生命周期](../Scripts/README.md#task-simulator-lifecycle)创建、复用和清理设备。

显式 ID 或共享配置里的 ID 不符合要求时会失败，避免悄悄换到其他运行时生成不同像素。要使用另一台符合要求的设备，可以运行 `SNAPSHOT_SIMULATOR_ID=<UDID> ./Scripts/test_snapshots.sh`。不要复用普通测试脚本的自动 destination 选择逻辑。

默认比较在缺少基准或图片不匹配时失败，不更新基准；脚本也会清除外部遗留的 `SNAPSHOT_RECORD`。运行结果保存在 `.output/snapshots/<时间>-<进程号>/compare.xcresult`，同目录包含环境信息、Simulator 清单和 `xcodebuild.log`。测试失败时还会尝试导出 xcresult 附件到 `attachments/`，便于查看实际截图、参考图和差异图。

### 显式更新基准

确认界面变化符合预期后，在相同环境下执行：

```bash
./Scripts/test_snapshots.sh --record
./Scripts/test_snapshots.sh
```

录制使用独立 scheme，结果保存为 `record.xcresult`。SnapshotTesting 1.19.7 的 `record: .all` 会在写入基准后报告 “Record mode is on” 测试失败，因此 `--record` 通常返回非 0；脚本保留该退出码，不能据此认定所有失败都是预期录制行为。检查日志确认图片已写入且没有构建或运行错误，逐张检查新增或变动 PNG，再单独运行默认比较，比较通过才算验收成功。默认比较使用 `record: .never`。

将已确认的 PNG 和相关代码一起提交。不要仅为通过测试放宽比较阈值或批量重录未解释的差异。CI 禁止使用录制参数。

如果修改了 `project.yml`，先运行 `./Scripts/generate_xcodeproj.sh` 更新生成项目。首次运行或依赖变化时，生成项目和 `xcodebuild` 可能需要解析 SwiftPM 包；本地按 [Agent 工作流](../Docs/agent-workflows.md#xcode-project-context) 设置网络环境。脚本不硬编码个人代理，CI 使用 runner 的网络配置。

### CI 与验证边界

[CI workflow](../.github/workflows/ci.yml) 在 iPhone job 的普通测试之后执行截图比较，复用该 job 的专属设备。三组普通测试分别是 iPhone / 27.2、iPad / 27.2 和 Duo / 27.1；截图只由 iPhone 18 Pro Max / 27.2 承载。工具链统一为 Xcode / SDK 27.2，允许当前 RC；缺少环境会明确失败，不跳过。成功、失败或取消时都先保存证据，再按 UUID 清理；上传任务目录中的 xcresult、日志、截图和 SHA-256 清单，保留 14 天。CI 中截图输出位于 `$CHINESE_CALENDAR_CI_OUTPUT_DIR/snapshots/`，本地默认仍为 `.output/snapshots/`。

27.0 → 27.2 的迁移先比较原图，12 张出现系统按钮颜色和列表缩进变化，检查后更新；其余 11 张保持不变。比较阈值未放宽。迁移与验收详见[任务记录](../Docs/Tasks/task-2026-10-28-ci-simulators/000-plan.md)。

升级 Xcode、SDK、runtime、SnapshotTesting 或基准设备时，需要明确评估并审查基准变化；不能用新环境静默覆盖旧环境的图。截图验证固定视口中的视觉结果，交互、导航、系统弹窗、下载流程和真机行为仍需各自验证。

任务范围及验收标准见 [当前界面截图基准方案](../Docs/Tasks/task-2026-10-24-ui-snapshots/000-plan.md)。
