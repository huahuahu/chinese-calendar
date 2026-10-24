# 系统 URL 统一入口：最终自动验证

- 日期：2026-10-24（Asia/Shanghai）。
- 基线：`dc76f6b5`；分支：`codex/issue-174-external-navigation`。
- 代码：8 个 Swift 文件的未提交修改，已删除全部自定义启动参数入口。
- 源码快照 SHA256：`82212d18e07bc6234a78db45138014ef844aedbab4f315b1249bd516dfaee481`。
- 算法：按 `git diff --name-only` 顺序拼接文件路径、NUL、内容、NUL；不包含新建任务文档。
- 原生 Xcode MCP `RunSomeTests`：24 个测试标识，展开参数后 27 个用例；27 passed / 0 failed / 0 skipped / 0 not run。包含构建与 App-hosted 测试。
- 工程：当前工作区 `ChineseCalendar.xcodeproj`，scheme `ChineseCalendar-iOS`。
- 设备：iPhone 18 Pro Max，iOS 27.0，UDID `CC76EE01-9792-4CDB-9DF3-1C37D928AB5E`。
- 环境调整：原配置设备 `16A9CAA7-45CE-46D5-8915-F61531FC617C` 已不在可用列表；临时使用当时处于 Shutdown 的同机型／runtime 设备，并同步本工作区共享配置与 Xcode 目标。完成后逐字恢复原配置，Xcode 目标恢复本轮开始时的 iPhone 18 Pro。没有把其他工作区专用设备作为替代。
- 格式：`./Scripts/format.sh --check`，0/358 文件需要修改。
- 严格 lint：`./Scripts/lint.sh`，345 文件，0 violations。
- 源码核对：`Sources`、`Apps`、`Scripts`、scheme 无 `--deep-link`、`openColdLaunchDeepLink`、旧一次消费标记及进程参数读取；仅应用根保留 `.onOpenURL`。
- 本轮未重跑手工 Simulator 交互或系统 URL 冷启动，不用自动测试替代该证据。

## 原生工具返回的结果

- ChineseCalendarUITests / deepLinkWithoutPresentationAppliesImmediately()：Passed
- ChineseCalendarUITests / dismissalWithoutARequestAllowsReopening()：Passed
- ChineseCalendarUITests / dynastyDeepLinkSelectsHistoryTab()：Passed
- ChineseCalendarUITests / emperorDeepLinkSelectsHistoryTab()：Passed
- ChineseCalendarUITests / externalDeepLinkKeepsTheRootPathAndModalAliveWhileWaitingForConfirmation()：Passed
- ChineseCalendarUITests / historyDestinationIDsIncludeEveryStableRecordID()：Passed
- ChineseCalendarUITests / historyPathPushPopAndTabRestorationKeepIndependentDestinations()：Passed
- ChineseCalendarUITests / historyRoutePreservesOrthodoxPeriodIdentity()：Passed
- ChineseCalendarUITests / laterDeepLinkCanReturnToCalendarAfterHistoryNavigation()：Passed
- ChineseCalendarUITests / manualDismissalDefersTheLatestDeepLinkUntilTheHostFinishes()：Passed
- ChineseCalendarUITests / parserSupportsAlternateSchemeAndMonthQuery()：Passed
- ChineseCalendarUITests / parserSupportsDynastyURLs()：Passed
- ChineseCalendarUITests / parserSupportsEmperorURLs()：Passed
- ChineseCalendarUITests / parserSupportsYearURLs()：Passed
- ChineseCalendarUITests / pushUpdatesSelectedTabPath()：Passed
- ChineseCalendarUITests / replacingYearsPathChangesItsCurrentDestination()：Passed
- ChineseCalendarUITests / "chinesecalendar://year/2026"：Passed
- ChineseCalendarUITests / "https://example.com/year/2026"：Passed
- ChineseCalendarUITests / "chinesecalendar://unsupported/2026"：Passed
- ChineseCalendarUITests / "chinesecalendar://year/not-a-year"：Passed
- ChineseCalendarUITests / tabPathsDoNotPolluteEachOther()：Passed
- ChineseCalendarUITests / targetedDismissalPreservesTheParentAndTabPaths()：Passed
- NavigationCoreTests / confirmationIsVisibleOnlyOnTopModalAndCancelKeepsTheTree()：Passed
- NavigationCoreTests / approvalWaitsForRootDismissalAndRejectsChildCompletion()：Passed
- NavigationCoreTests / requestDuringApprovedDismissalRequiresItsOwnApproval()：Passed
- NavigationCoreTests / coldRequestDoesNotRequireConfirmation()：Passed
- NavigationCoreTests / primaryDeepLinkCancellationAndApprovalWaitForTheRootDismissal()：Passed
