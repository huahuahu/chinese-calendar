# Issue #135：Duo 工具栏适配

关联：[Issue #135](https://github.com/huahuahu/chinese-calendar/issues/135)。

## 实现

- iOS 27.1 起根据 `toolbarVerticalEdge` 选择标签样式：`nil` 时显示“今天”，有值时使用 `.automatic`。
- 工具栏位置遵循系统默认行为；较早系统保留文字按钮，日期选择动作不变。
- 增加包含 `CalendarHomeView` 完整导航层级的 Preview。

`toolbarVerticalEdge` 表示系统的竖栏偏好，不表示按钮当前所在轴向。
`.automatic` 在顶部横向工具栏中也可能只显示图标。

## 验证（2026-10-05）

- 最终源码在 Xcode 27.1 Beta / iOS 27.1 SDK 构建通过，scheme 为 `ChineseCalendar-iOS`，目标为 `iPhone Duo (issue-135)`。
- 三个 Swift 文件通过 SwiftFormat 与 SwiftLint strict；`git diff --check` 通过。
- 最终版本尚未重新执行完整设备交互矩阵，早期实验版本的点击结果不作为最终版本验收依据。
- CI 使用 GitHub 的 `xcode-27` runner，固定选择 Xcode 27.1，以提供 `toolbarVerticalEdge` 所需的 iOS 27.1 SDK。

## 剩余项

- Canvas 外屏遮挡、完整折叠／方向／尺寸覆盖、导航返回及普通 iPhone 回归尚未全部完成，#135 保持打开。
