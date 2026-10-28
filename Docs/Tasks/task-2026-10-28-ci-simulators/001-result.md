# CI 任务专属模拟器与 27.2 环境：结果

- 方案：[000-plan.md](000-plan.md)
- 关联：[PR #194](https://github.com/huahuahu/chinese-calendar/pull/194)
- 记录日期：2026-10-28
- 代码状态：本 PR 的实现及 25 张基准散列记录，已同步主分支 `90594d0e`（PR #193），对应合并提交 `f5332a21`；本地检查针对带本次改动的工作区。

## 实际结果与方案调整

- 三设备串行矩阵：iPhone 18 Pro Max / iOS 27.2、iPad Pro 13-inch (M5) / iOS 27.2、iPhone Duo / iOS 27.1，工具链统一 Xcode / SDK 27.2。`setup-xcode` 使用 `27.2` 选择器；当前 RC 的 licenseType 为 GM，符合此 action 的稳定类型筛选，不能据此将 RC 称作正式版。仓库变量 `CI_XCODE_VERSION` 可调整选择，脚本仍要求 27.2。
- 保留现有 GitHub 托管 `xcode-27` runner。调查旧 run `40333993041` 的 jobs，runner 名称为 GitHub Actions；因此没有将本机 RC 的绝对安装路径写入 CI。checkout 外目录在自托管机器上可持久保留，托管宿主销毁后由上传的 artifact 保留证据。
- `ci_simulator.py start` 先验证工具链和 `runtime.supportedDeviceTypes`，为每个任务新建独占设备，再记录 UUID。任务内重复调用复用设备；任务结束目录不可重用。runtime 的版本号相同不代表机型兼容，本机的 Duo 专用 27.2 runtime 会被普通 iPhone / iPad 过滤掉。
- 测试和构建共用显式任务 UUID，缺失时失败；普通测试关闭自动 Simulator 克隆，保留 xcresult。快照只在 iPhone job 执行。`Scripts/ci.sh` 的本地完整 CI 也创建任务设备，以 EXIT / INT / TERM 收尾并比较快照。
- `finish` 在删除前保存设备库存，已启动时尽力保存截图和日志；验证 UUID、设备名称、型号和 runtime 的归属后删除。中断创建可从预先登记的唯一名称恢复实际 UUID，归属冲突时拒绝操作。清理后生成证据 SHA-256 清单；异常残留可用状态文件显式恢复清理。
- 原工作区分配器同步固定至 27.2，仍负责本地共享 MCP 上下文协调。它不负责隐式管理整个实验生命周期，独立实验使用显式 start/finish 入口。

## 截图迁移

先用 Xcode 27.2 RC build 27B48、SDK 27.2、iOS 27.2 build 24B114 和专属 arm64 iPhone 比较旧基准。25 张中 14 张出现差异，已逐张查看旧图与新图：9 张日历图的“今天”按钮从强调色变为浅色下黑色／深色下白色；年份选择器和设置页的系统列表缩进变化，历史时间线三个外观场景的说明文字缩进变化。页面内容和业务数据保持不变。

显式录制后，独立执行比较，6 个测试分组全部通过，覆盖全部 25 张 PNG；14 张更新、11 张散列未变。`precision: 1` 和 `perceptualPrecision: 0.99` 保持不变。录制阶段的 6 个分组因 `Record mode is on` 失败属于预期记录行为，不计作比较通过。每张图片的新旧 SHA-256 和变动边界见 [baseline-migration.json](evidence/baseline-migration.json)。

## 验收证据

| 验收项 | 状态 | 实际证据与边界 |
| --- | --- | --- |
| AC-01 | 本地已验证 | 三组真实设备创建成功；13 项生命周期测试包含错误版本、缺失／不兼容／歧义 runtime 拒绝，截图入口另覆盖 Duo 专用同版本 runtime |
| AC-02 | 本地已验证 | iPhone 和 iPad 同任务重复 start 返回相同 UUID；隔离测试验证不同任务获得不同设备、不借用原有设备 |
| AC-03 | 本地已验证 | 三组本任务设备均按状态文件删除；iPhone 的比较前后及录制 xcresult、540 项测试 xcresult 和构建日志已先复制到实验目录，再执行 finish；测试覆盖诊断失败、归属变化、创建中断恢复、重复清理。workflow 使用 always 清理和上传；真实 GitHub 取消场景未触发 |
| AC-04 | 本地部分验证，远程待完成 | 原生 Xcode MCP 在专属 iPhone 上运行 ChineseCalendar-iOS：540 passed / 0 failed；BuildProject 成功。测试／构建 shell 使用同一显式 UUID 已有回归覆盖。iPad / Duo 本轮只实测创建与清理，完整 app 测试由 PR 矩阵执行 |
| AC-05 | 已验证 | 原生 Xcode MCP 的 ChineseCalendarSnapshots：6 passed / 0 failed，覆盖 25 张 PNG；逐张核查差异，11 张基准散列保持不变 |
| AC-06 | 本地已验证，远程待完成 | 43 项 Python 测试、3 项 Node 测试通过；SwiftFormat 363 文件无修改、SwiftLint 350 文件零违规；335 项本地化资源和 919377 条 JSONL schema 检查通过；actionlint、Bash 语法、diff 检查通过 |

本机归档目录为 `~/Library/Logs/ChineseCalendar/experiments/ci-27-2-main-sync/`（主分支同步后验证）及 `ci-27-2-migration/`（初次验证），包含原生 MCP 的 xcresult、日志、像素差异统计和清理归属；它是补充排查材料。可长期核查的基准图片、散列和验收结论随 PR 保存。

## 剩余边界

本轮未运行独立的 `review-changes` 审查任务、真机交互或发布。原生 MCP 的测试与构建不能替代 PR 最新提交的远程矩阵，远程状态以 PR 检查为准。runner 硬杀可能无法执行 always；状态记录支持持久宿主上的后续恢复，不保证托管 VM 销毁后还能访问本地文件。

## 2026-10-29：远程环境准备修复

首次远程 [run 40714384081](https://github.com/huahuahu/chinese-calendar/actions/runs/40714384081) 在 `12ba750a` 上完成：Lint 和 Duo job 通过；iPhone、iPad 均因缺少兼容 iOS 27.2 runtime，在创建设备前明确失败。托管镜像安装 Xcode 27.2 RC 不代表已经安装通用 iOS 27.2 runtime。

- 新增 `prepare-runtime`：保存安装前后库存，已有唯一兼容 runtime 时复用，否则通过 Xcode 安装指定版本，再按 `supportedDeviceTypes` 校验；安装失败、未产生兼容 runtime、出现歧义时都保留失败，不降级版本或跳过设备。
- CI 显式选择 Bash，启用其 `-eo pipefail`，测试／构建经 tee 保存日志时仍传播原始退出码。runtime 安装前就记录 commit，未创建设备时收尾也能保存环境诊断，不再因缺少 simulator.json 产生第二个错误。
- 本地生命周期测试由 13 项扩至 18 项，新增复用、缺失时安装、安装后仍不兼容、歧义和下载失败场景；测试全部通过。actionlint、Python 3.9 语法和 diff 检查通过。本次未修改 App 代码或快照。
- 后续远程验收以 PR 最新提交的完整矩阵为准；首次失败的 run 不作为新提交的验收证据。
