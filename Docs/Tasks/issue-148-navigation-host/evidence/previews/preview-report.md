# Issue #148 独立 Preview 验证

- 工具：原生 Xcode MCP `RenderPreview`，项目与 scheme 按 `.xcodebuildmcp/config.yaml` 对齐。
- 实际渲染目的地由 Preview 管线选为 iPhone Duo / iOS 27.1；与交互测试使用的 iPhone 18 Pro Max / iOS 27.0 分开记录。

## 已通过

`CalendarHistoryHomeView.swift` 的两个独立 Preview 均迁移到 `SampleNavigationPreview(tab: .history)`。它们读取 sampleData host 的根配置，使用和 App 一致的 `NavigationScopeView`。

| Preview | 实际快照检查 |
| --- | --- |
| 示例数据 | [history-sample.png](history-sample.png)：显示朝代标题、明朝示例资料、时间线和跳转标记，单个导航容器 |
| 空状态 | [history-empty.png](history-empty.png)：显示朝代标题及“没有可显示的朝代”，没有空白或重复导航栏 |

初次渲染被 Xcode 生成的 `__designTimeSelection` 重载歧义阻断，位置为 `ForEach(..., content: dynastyTimelineRow)`。改为显式尾随闭包后两个 Preview 均构建、渲染成功，保留同一个 row 构建函数与数据身份。原诊断见 [history-initial-diagnostic.txt](history-initial-diagnostic.txt)。

## 下载演示快照边界

`FullStoreDownloadPreview` 独立 Preview 由 `FullStoreDownloadPreviewHost.task` 自动呈现 full-screen。原生工具两次均返回无错误，但第一张 [download-transition.png](download-transition.png) 处于呈现动画中，第二张 [download-retry.png](download-retry.png) 为白色根页；没有据此宣称稳定渲染通过，也未通过修改实际呈现生命周期来规避快照时序。

下载演示的双 Tab 完整布局、子详情、关闭和重开使用 [Simulator 实际交互记录](../runtime/runtime-report.md) 验证。Preview 快照不替代触摸交互。
