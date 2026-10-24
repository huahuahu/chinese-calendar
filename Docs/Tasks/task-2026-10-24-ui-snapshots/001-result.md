# 当前界面截图基准：结果

- 方案：[000-plan.md](000-plan.md)
- 记录日期：2026-10-24
- 代码状态：验证时为 `codex/ui-snapshot-baselines` 未提交工作区；基础 HEAD 和已验证实现文件摘要见 [source-state.json](evidence/source-state.json)，提交前按摘要核对一致。

## 实际结果

新增 App 承载的 `ChineseCalendarSnapshotTests` target，测试专用 SnapshotTesting 固定为 1.19.7；生产 Swift Package 和页面实现未修改。23 张 PNG 使用现有 `PreviewSampleData`，分别由 16 个 iPhone 浅色场景、4 个 iPad 横屏场景、2 个深色场景和 1 个最大辅助功能字号场景组成。矩阵、环境及运行方法见 [Tests/README.md](../../../Tests/README.md)。

测试在共享配置的 `chinesedate iPhone 18 Pro Max (885f)`（`16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0，arm64）上使用原生 Xcode MCP 执行。先读取共享配置、打开项目并切换 scheme/destination。iPhone 画布固定 390×844，iPad 画布固定 1366×1024，1× PNG；日期、简体中文、上海时区、字号、外观和用户偏好固定。

每个场景独占内存容器和页面状态。实际前台 UIWindowScene 承载页面，等待连续四帧一致后比较；错误尺寸、未成功绘制或未稳定会失败。截图先经 PNG 解码，保证实际图与磁盘基准具有一致的颜色精度。所有像素参与比较（`precision: 1`），仅允许小于 1% 的感知色差（`perceptualPrecision: 0.99`）。

比较和录制各有独立 scheme。日常模式使用 `.never`，缺图和不匹配均失败；录制 `.all` 会按库设计写入图后报预期失败，必须再跑比较。CI 已接入默认比较及失败诊断上传，不允许录制。

## 方案调整及边界

- 完整 `CalendarHomeView` 内部仍新建使用真实今天的日期模型，本次以 `CalendarPageView` 固定日历页面内容，不为截图而调整生产数据流。
- 设置固定 `.starting` 状态，使用独立 AppStorage 域，不运行准备数据库或下载；未覆盖 ready/下载中的设置状态。
- 首次逐像素比较连续两轮发现玻璃按钮边缘 14–43 个像素、每通道 1/255 的波动。检查实际 PNG 差异后设置上述感知容差；还统一 PNG 解码路径，解决渲染缓冲区与持久化图像在感知比较中的精度差异。保留首次录制的全部基准，未以覆盖图片消除失败。
- 页面截图只覆盖固定初始视口。最大字号下现有布局也按当前效果记录，没有趁机修改 UI。未做完整 Tab 容器、滚动、导航手势、系统弹窗、下载流程或真机验证。

## 验收证据

| 验收项 | 状态 | 证据 |
| --- | --- | --- |
| AC-01 | 已验证 | SnapshotSampleHost 复用现有数据，生产 Sources 无 diff；截图 target 构建通过 |
| AC-02 | 已验证 | 23 张 PNG 合计约 3.42 MB，按三组联系表检查内容、空态、历史三栏、深色和大字号；基准摘要见 [baseline-sha256.json](evidence/baseline-sha256.json) |
| AC-03 | 已验证 | [首次通过](evidence/snapshot_compare4.json) 4/4；恢复负向验证文件并完善绘制成功检查后，[最终通过](evidence/snapshot_final.json) 4/4、23 图；全部基准摘要不变 |
| AC-04 | 已验证 | 临时给深色基准涂红块并移走大字号基准，分别得到不匹配及缺图失败；缺失文件未被自动生成。见 [负向验证](evidence/snapshot_negative.json)。随后按原始摘要完整恢复 |
| AC-05 | 本地配置已验证，远程未运行 | 脚本 bash -n、设备选择模拟输入、CI YAML 检查通过；本地执行使用 MCP，未直接执行 CLI 入口，也未运行远程 CI |
| AC-06 | 已验证 | [原有测试 489/489](evidence/existing-tests.json)；[格式检查](evidence/format-final.txt) 0 文件需修改；[strict lint](evidence/lint-final.txt) 0 violations；git diff --check 通过 |

本轮未单独执行代码 review。工具返回的 xcresult 路径属于本机临时产物，精简结果和基准摘要保存在本目录；未来 CI 失败产物由 workflow 上传。
