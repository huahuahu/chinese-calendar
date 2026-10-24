# 呈现接口简化：结果

- 方案：[002-native-dismissal.md](002-native-dismissal.md)
- 日期：2026-10-24
- 代码状态：基于 `c2ef6b0333a717da1a8b4f573b01ac4e98e446d8` 的未提交工作区；保留开始前已有改动，本轮没有提交、推送或修改 PR。
- 源码快照：对 `git ls-files Sources Scripts/NavigationCoreAPI` 中仍存在的 `.swift` 文件，按路径排序依次拼接路径、NUL、内容、NUL，SHA-256 为 `6bfad204cf9f8dd5312481f8a396a0b88ce97d959c5bb1b6032ca475cebbb17f`。文档后续整理不改变此源码快照。

## 实际实现

- `present` 删除 `configuration` 参数，使用 `onDismiss`。根配置供根页面、栈根、push 及嵌套模态共用。
- 年份路由直接携带稳定 UUID、年份 Binding 和本次 ModelContext。删除 CalendarYearPickerSession 及配置工厂；一次消费、来源隔离和 store generation 校验放在发起方的 Binding setter，保留边界月份过渡。
- 下载演示路由携带同一业务 state，父页面、Tab 根和子详情直接共享；正式下载详情主动取消时同步清理自己的 active 状态。
- 删除 NavigationPresentationEndpoint、NavigationPresentationRenderRecord、NavigationModalMount（含 ModalLifecycleController、HostLifetime）和独立的 NavigationLayerRouteState。内部请求对象仅保留关闭配对状态及一次性回调，删除 observer、拆除等待关系和通知重入队列。
- sheet／fullScreenCover 仅在原生 onDismiss 中取出回调并通知。拒绝、未展示取消、宿主或 Router 销毁不补发通知。alert 保留原生关闭后的异步按钮处理及导航串行协调。
- handle 弱引用请求与 Router；Context 不强持入口路由。退出动画由节点保留参数，旧入口不继续保活 Binding 捕获的业务对象。内部节点、身份和事务继续不公开。

## 验证

环境：原生 Xcode MCP，`ChineseCalendar.xcodeproj`，`ChineseCalendar-iOS` scheme，配置指定的 `chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0 Simulator，Xcode 27.1 RC。

| 项目 | 结果与证据 |
| --- | --- |
| iOS 构建及测试目标构建 | BuildProject（buildForTesting=true）通过，0 编译错误；最终构建记录时间 2026-10-24 11:53:56 |
| 完整自动测试 | RunAllTests：489 通过、0 失败、0 跳过、0 未运行；执行开始时间 2026-10-24 11:54:12 |
| 实际 SwiftUI 宿主 | 覆盖 sheet／fullScreen 原生关闭一次通知、关闭前保留及关闭后释放捕获、同轮取消不通知、根配置继承、嵌套呈现、关闭回调重入和延迟导航、alert 异步动作等待 |
| 业务状态与参数 | 覆盖 Binding 变化后稳定哈希、普通路由完整值比较、不同来源隔离、一次结果消费、旧 Binding 和旧回调失效、store 替换、旧 Context 不保活来源、嵌套及排队资源释放 |
| 公开 API 边界 | `validate_navigation_public_api.py`：正常用法通过，18 个内部类型／状态／手动通知的负向编译用例均按预期拒绝；本地产物 `.output/navigation-public-api/report.json` |
| 格式与 strict lint | `Scripts/format.sh --check` 通过；`Scripts/lint.sh` 0 violations |
| 其他本地 CI 检查 | 本地化 337 项通过；919377 条 JSONL schema 校验通过；seed-store Node 测试全部通过；`git diff --check` 通过 |
| 手动交互及远端 CI | 本轮未进行手势取消、宽窄布局和真机验证；未推送，未触发远端 CI。自动真实宿主测试不替代这些证据 |

第一轮完整回归为 485 通过、4 失败，均为旧契约断言：未展示取消应调用结束回调、无宿主提交应拒绝、主动取消后暂留 handle、过期 Context 永久保留入口。按已确认的新边界调整对应断言后，以上完整回归全部通过。

完整测试结果由 Xcode MCP 保存于本机 ActionArtifacts，运行标识为 `53A610D1-454F-46F6-A2DE-ECBE84482848`；`.xcresult` 名为 `Test-ChineseCalendar-iOS-2026.10.24_11-54-12-+0800.xcresult`。这些本机产物不是远端 CI 证据。
