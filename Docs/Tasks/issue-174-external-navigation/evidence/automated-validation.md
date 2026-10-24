# 自动验证摘录

> 历史证据：对应仍支持自定义启动参数的初版快照。用户后续要求统一为系统 `.onOpenURL`，现已删除 `--deep-link` 通道；本记录不代表最终快照重跑结果。

- 日期：2026-10-24（Asia/Shanghai）
- 基线：`dc76f6b5`；分支：`codex/issue-174-external-navigation`，7 个 Swift 文件的未提交修改。
- 源码快照 SHA256：`2cd21ca8c0dbfa9241ec8bce0826f6405ccda2575a23210fbd9eeab2782e7f62`。
- 摘要算法：按 `git diff --name-only` 顺序拼接各文件相对路径、NUL、文件内容、NUL，计算 SHA256；不包含新建任务文档。
- 工程：`ChineseCalendar.xcodeproj`；scheme：`ChineseCalendar-iOS`。
- Simulator：`chinesedate iPhone 18 Pro Max (885f)`，iOS 27.0，UDID `16A9CAA7-45CE-46D5-8915-F61531FC617C`。
- 原生 `RunSomeTests` 返回结果包不完整；随后 `GetBuildLog` 确认 `The build succeeded`、无编译错误。该次不计为测试通过。
- 按共享配置核对 `session_show_defaults` 后，使用 XcodeBuildMCP `test_sim` 和 40 个 `-only-testing` 选择器重跑。
- 选择：`CalendarRouterTests.swift`、`CalendarPresentationTests.swift`、`CalendarPresentationRoutingTests.swift`、`CalendarNavigationContextTests.swift` 的 35 个 App-hosted 测试，以及下方列出的 5 个 Core 测试。
- 结果：40 passed / 0 failed / 0 skipped，工具耗时 186.8 秒。参数化案例包含在对应测试中。
- 构建警告来自既有代码（weak 变量、废弃 API 等），未修改这些范围外内容。
- `./Scripts/format.sh --check`：0/358 files require formatting，106 skipped。
- `./Scripts/lint.sh`：0 violations，0 serious，345 files。
- `git diff --check`：通过。

以下摘自该次测试日志，仅保留测试结果，不复制完整构建输出：

```text
✔ Test rootSelectionProjectsTheCurrentTabDestination() passed after 0.003 seconds.
✔ Test primaryRootSelectionDoesNotInventATab() passed after 0.002 seconds.
​✔ Test rootAndLocalOperationsUseTheSamePathForEveryTab(tab:) with 3 test cases passed after 0.002 seconds.
✔ Test historyModalPushAndNestedPresentationPreserveTabNavigation() passed after 1.377 seconds.
✔ Test appDeepLinkWaitsForConfirmationWithoutChangingTheSourceNavigation() passed after 1.320 seconds.
✔ Test appRootAndTabRootsAreExplicit() passed after 0.010 seconds.
​✔ Test navigationStateAcceptsAppDestinationsWithoutEntryAllowlist(destination:) with 4 test cases passed after 3.069 seconds.
✔ Test backgroundPresentationDoesNotLeaveADebugSessionBehind() passed after 1.072 seconds.
✔ Test debugNavigationPushUsesTheSettingsStack() passed after 0.001 seconds.
✔ Test mainTabsModalAndItsChildKeepRootSelectionsAndEveryTabPathIndependent() passed after 1.283 seconds.
✔ Test replacedRootAndModalTabRootsKeepIndependentPathsAndSelections() passed after 0.763 seconds.
✔ Suite "App 使用局部导航框架" passed after 8.913 seconds.
✔ Test manualDismissalDefersTheLatestDeepLinkUntilTheHostFinishes() passed after 1.084 seconds.
✔ Test dismissalWithoutARequestAllowsReopening() passed after 1.631 seconds.
✔ Test targetedDismissalPreservesTheParentAndTabPaths() passed after 2.736 seconds.
✔ Test rejectedAndSynchronouslyCancelledDetailsAllowANewRequest() passed after 0.019 seconds.
✔ Test disappearingDownloadOnlyClosesItsOwnDetails() passed after 2.203 seconds.
✔ Test disappearingProgressCancelsAnUnshownRequest() passed after 0.019 seconds.
✔ Test repeatedLaunchCheckDoesNotOverwriteLaterNavigation() passed after 0.001 seconds.
✔ Test previewOwnerReleasesAfterActualFullscreenDismissalAndCanReopen() passed after 2.104 seconds.
✔ Suite "页面呈现与下载资源所有权" passed after 4.349 seconds.
✔ Test pushUpdatesSelectedTabPath() passed after 0.001 seconds.
✔ Test tabPathsDoNotPolluteEachOther() passed after 0.001 seconds.
✔ Test historyRoutePreservesOrthodoxPeriodIdentity() passed after 0.001 seconds.
✔ Test historyPathPushPopAndTabRestorationKeepIndependentDestinations() passed after 0.001 seconds.
✔ Test historyDestinationIDsIncludeEveryStableRecordID() passed after 0.001 seconds.
✔ Test replacingYearsPathChangesItsCurrentDestination() passed after 0.001 seconds.
​✔ Test externalDeepLinkKeepsTheRootPathAndModalAliveWhileWaitingForConfirmation(coldLaunch:) with 2 test cases passed after 2.506 seconds.
✔ Test coldLaunchDeepLinkAppliesImmediately() passed after 0.002 seconds.
✔ Test dynastyDeepLinkSelectsHistoryTab() passed after 0.001 seconds.
tBarrier✔ Test emperorDeepLinkSelectsHistoryTab() passed after 0.010 seconds.
​✔ Test emptyOrInvalidLaunchArgumentsAreConsumedOnce(arguments:) with 4 test cases passed after 0.019 seconds.
​✔ Test systemURLParsingOnlySubmitsSupportedLinks(urlString:) with 4 test cases passed after 0.016 seconds.
✔ Test parserSupportsYearURLs() passed after 0.001 seconds.
✔ Test parserSupportsDynastyURLs() passed after 0.001 seconds.
✔ Test parserSupportsEmperorURLs() passed after 0.001 seconds.
✔ Test parserSupportsLaunchArguments() passed after 0.001 seconds.
✔ Test run with 35 tests in 2 suites passed after 21.281 seconds.
✔ Test primaryDeepLinkCancellationAndApprovalWaitForTheRootDismissal() passed after 0.080 seconds.
✔ Test coldRequestDoesNotRequireConfirmation() passed after 0.080 seconds.
✔ Test requestDuringApprovedDismissalRequiresItsOwnApproval() passed after 0.080 seconds.
✔ Test confirmationIsVisibleOnlyOnTopModalAndCancelKeepsTheTree() passed after 0.080 seconds.
✔ Suite "普通根层的导航请求与栈根替换" passed after 0.082 seconds.
✔ Test approvalWaitsForRootDismissalAndRejectsChildCompletion() passed after 0.080 seconds.
✔ Suite "局部 Router 与导航事务" passed after 0.081 seconds.
✔ Test run with 5 tests in 2 suites passed after 0.083 seconds.
```
