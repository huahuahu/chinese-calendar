# 测试

跨模块测试与截图基准放在本目录。普通业务测试仍使用 `./Scripts/test.sh`；截图测试有独立的环境约束和入口。

## 当前界面截图基准

`Tests/Snapshots` 中的 App 承载测试通过 Point-Free SnapshotTesting **1.19.7** 比较当前 SwiftUI 界面，基准 PNG 保存在 `Tests/Snapshots/__Snapshots__`，随代码提交。测试复用项目内存示例数据，固定日期、简体中文、上海时区、外观、字号和视口。iPhone 视口为 390 × 844 pt，iPad 横屏视口为 1366 × 1024 pt，均以 1× 渲染。宽屏场景在测试内部固定虚拟 iPad 尺寸，承载测试的 Simulator 始终使用下表中的 iPhone。

| 项目 | 基准环境 |
| --- | --- |
| Xcode | 27.1 |
| iPhoneSimulator SDK | 27.1 |
| Simulator runtime | iOS 27.0 |
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

页面经真实前台 `UIWindowScene` 渲染；连续稳定帧、正确视口和成功绘制均须满足才能截图。基准比较前按 PNG 解码统一色彩精度，使用 `precision: 1`、`perceptualPrecision: 0.99`：每个像素都参与比较，只允许很小的感知色差。最初两次逐像素比较发现系统玻璃按钮边缘有 14–43 个像素的单通道 1/255 波动，因此采用该容差；不允许忽略一块区域或容忍一定比例的任意错图。

当前覆盖日历页面内容；完整 `CalendarHomeView` 内部仍会读取真实“今天”，尚未纳入固定日期基准。设置只覆盖未启动数据库准备的 `.starting` 状态。滚动页面固定初始视口，截图不表示已经覆盖视口外全部内容，也不证明交互或辅助功能布局符合预期。

### 比较已有基准

在仓库根目录执行：

```bash
./Scripts/test_snapshots.sh
```

脚本会严格检查工具链、SDK、runtime、机型和架构。设备选择按以下顺序进行：

1. 显式的 `SNAPSHOT_SIMULATOR_ID`。
2. 本地 `.xcodebuildmcp/config.yaml` 中的 `sessionDefaults.simulatorId`；CI 不读取个人设备 ID。
3. 找到可用的 iPhone 18 Pro Max / iOS 27.0，或在该 runtime 已安装时创建同型号设备。

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

[CI workflow](../.github/workflows/ci.yml) 在现有普通测试之后执行截图比较。`xcode-27` runner 必须具备 Xcode 27.1、arm64 和 iOS 27.0 runtime；缺少环境会明确失败，不跳过。失败时上传 `.output/snapshots/`，包含 xcresult、日志及已导出的附件，保留 14 天。

升级 Xcode、SDK、runtime、SnapshotTesting 或基准设备时，需要明确评估并审查基准变化；不能用新环境静默覆盖旧环境的图。截图验证固定视口中的视觉结果，交互、导航、系统弹窗、下载流程和真机行为仍需各自验证。

任务范围及验收标准见 [当前界面截图基准方案](../Docs/Tasks/task-2026-10-24-ui-snapshots/000-plan.md)。
