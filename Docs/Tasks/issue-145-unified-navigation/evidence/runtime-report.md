# Issue #145 常规 Simulator 交互复验

- 时间：2026-10-07 10:58–11:09（Asia/Shanghai）。
- 版本：HEAD `88e3b74ae7bab044389a9a471346e16f9880bd1c` + 实施未提交代码；实际安装由主 Agent 在测试后通过原生 InstallAndRun 完成。本轮开始时对 Sources/Apps 所有 Swift 文件采集了 SHA-256：`Docs/Tasks/issue-145-unified-navigation/evidence/runtime-source-sha256.txt`。后续主 Agent 修改 picker ID/幂等 guard，未重新安装，因此本报告是修复前二进制。
- 设备：`chinesedate iPhone 18 Pro Max (885f)`，`16A9CAA7-45CE-46D5-8915-F61531FC617C`，iOS 27.0，竖屏。
- 原生交互 session：`Issue 145 Verification`，workspace `workspace-deC0lVsFJy`，scheme `ChineseCalendar-iOS`。始终 Running，无观察到崩溃。
- 操作：原生 DeviceInteractionSynthesize；点击均基于前一步 hierarchy hitPoint。没有调用备用 UI MCP。两套 MCP 都没有 URL opener，故仅向指定 Simulator 使用 `xcrun simctl openurl`；首次系统 Open 确认由真实 hierarchy 点击，后续链接直接送达。
- 数据：开始和模拟下载结束后，设置均显示已安装完整日期数据；未清空、未重装、未改数据文件。没有执行真实 store identity 切换。

## 通过的实际交互

| 场景 | 观察与证据 |
| --- | --- |
| 首页 picker 定位、高亮 | 2026 在列表中部，勾选及 AX Selected 一致。`01-picker-2026.png/.txt` |
| 同年、较早、较晚 | 点击 2026，仍为八月；选 2025，原页变为乙巳年十二月；再选 2027，原页变为丁未年正月。无额外 push。 |
| 关闭、下滑、重开 | 按钮关闭与从 sheet 导航栏下滑都保留 2027；再次打开仍高亮 2027。 |
| 另一个日历 destination 与隔离 | picker 可见时打开 year/-1，关闭 picker 后进入公元前2年的带返回按钮日历页；再次 hot link year/0 到公元前1年。该页 picker 显示 BCE1/CE1 相邻，无公元0年；选 CE1 正确返回当前 destination。返回首页仍是2027。`02-picker-hot-link-bce.png/.txt`、`04-bce-ce-picker.png/.txt`、`05-origin-selection-preserved.txt` |
| 模拟详情实时与手动关重开 | 实际采样 4%→20%，手动关闭时附件30%，重开46%，随后完成，最终自动关闭到设置、附件消失。`06`–`12` hierarchy 文件。没有精确计时两秒。 |
| 模拟详情 hot deep link | 详情可见时发 year/2024，sheet 关闭、目标日历2024出现，下载仍在后台继续并显示附件。`13-download-hot-link.txt` |
| 演示阶段、字号、Tab、嵌套详情 | 选择100%尚未校验，再选辅助功能最大；子sheet显示100%且校验待开始，文字可读。关闭回演示仍100%；切换检查Tab并切回，阶段和字号保持；完成回设置，重开重置默认/准备。`14-demo-child-max-type.png/.txt` |
| 演示 full-screen hot link | full-screen可见时 year/2023，关闭后进入2023日历。`15-demo-hot-link.txt` |
| 演示子sheet hot link | 子详情可见时 year/2022，子sheet/full-screen整树消失并到2022日历，无残留蒙层。`16-demo-child-hot-link.txt` |
| 连续不同 deep link | picker可见时依次发送 year/2020、year/2021，第二次开始距第一次开始173ms，两次返回成功；最终只有2021 destination。`17-consecutive-link-dispatch.json`、`17-consecutive-link-result.png/.txt`。`runtime-console.log` 记录第一次在11:07:56.292767进入 Deferred，第二次在11:07:56.452882仍进入 Deferred，直到11:07:56.904129才 Applied；结合最终2021画面，证明两次请求均在关闭等待阶段协调，并由最后一次覆盖。没有逐帧测量动画。 |
| 历史 push/pop/Tab隔离 | 朝代→西汉→年号→前元，返回年号；切日历仍为2021，切回朝代仍为西汉年号列表，返回按钮仍指向西汉。`18-history-switch-calendar.txt`、`19-history-path-preserved.png/.txt` |

## 实际发现与剩余边界

1. **已反馈、待修复后复验：** 公元前2年（year/-1）destination 打开 picker，稳定停在公元前100年前后，当前年不可见。`03-bce-picker-position.png/.txt`。主 Agent 已核对并修改 section/row ID 命名空间，需安装最终代码后复验。
2. **视觉观察：** 公元前日格的民用日期长文本会拆成多行，个别日期末位单独换行（如「2-02-0 / 5」）；内容仍可见，没有重叠。该布局不属于本轮导航改动，未另行修改。截图 `02`。
3. 真实下载详情验证使用真实 coordinator 的模拟入口，不等于真实安装或容器切换。受控内存容器切换由后续专门验证承担，不能以本轮通过代替。
4. 本轮是一个竖屏 iPhone Simulator；未做真机、横屏、Duo、VoiceOver 或精确动画时间测量。最大字号只覆盖演示/其子详情。
5. 当前停在朝代Tab的西汉年号列表；session保持开放，已交还主 Agent 做下一轮构建/受控容器切换。

## 后续专项结果

BCE定位修复与受控内存container/identity替换的两条场景均已复验通过，见 `store-runtime.md` 和持久证据 `evidence/store-runtime-report.md`。该专项不等同于真实网络下载/文件安装；临时harness由主 Agent 移除并重新安装最终产品代码。

## 正式代码恢复后的最终冒烟（11:16–11:17）

主 Agent 已移除临时harness，以仅继承scheme参数重新原生安装运行；本 Agent 复核 `final-source-sha256.txt`，205个Swift文件哈希全部一致。

- 设置明确显示「已安装完整日期数据」。`30-final-full-data-installed.png/.txt`。
- 首页为真实2026八月，picker为完整连续年份列表，2026居中勾选。按钮关闭回原首页，重开仍为2026且没有残留模态。`31-final-picker-reopen.png/.txt`。
- 再次关闭后停在正式首页，无下载附件或验证模态，App Running。`32-final-calendar.txt`。
- 已交还全部设备交互权，由主 Agent 关闭session。此轮只做恢复后的短冒烟，不重复声称运行完整矩阵。
