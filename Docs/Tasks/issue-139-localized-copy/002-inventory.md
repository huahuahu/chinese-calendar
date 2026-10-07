# Issue #139 文案迁移清单

## 资源范围

共 **254 项**资源，全部归属 `ChineseCalendarLocalization`：其中 8 项供已有 Core 日期格式 API 使用，246 项供 UI 功能使用。一个资源可以有多个语义相同的调用点；计数是定义数，不是替换次数。

| 命名空间 | 定义数 | 覆盖内容 |
| --- | ---: | --- |
| `Calendar` | 40 | 日历标题、年月导航、世纪索引、月格空状态、选中日、今天的朗读，以及 Core 年月日格式 |
| `Common` | 15 | 关闭/完成/重试/确认动作、日期精度与索引、缺失值、通用恢复提示 |
| `History` | 108 | 朝代时间线、起讫与来源比较、皇帝/年号列表与详情、统计、时长、卡片朗读 |
| `Settings` | 46 | 外观、数据状态、清空确认与结果、App 内可见的下载调试页 |
| `Store` | 45 | 初始化、数据层级、下载各阶段/步骤/百分比、错误分类与恢复建议 |

## 已迁移调用点

以下文件的产品文案均改为统一成员或函数访问。仅改变文字来源及必要的资源类型适配；页面布局、导航、日历选择、下载和取消流程不变。

### App

- [App/ChineseCalendarRootView.swift](../../../Sources/ChineseCalendarUI/App/ChineseCalendarRootView.swift)
- [App/Store/ChineseCalendarStoreCoordinator.swift](../../../Sources/ChineseCalendarUI/App/Store/ChineseCalendarStoreCoordinator.swift)
- [App/Store/FullStoreDownloadDetailView.swift](../../../Sources/ChineseCalendarUI/App/Store/FullStoreDownloadDetailView.swift)
- [App/Store/FullStoreDownloadPhase.swift](../../../Sources/ChineseCalendarUI/App/Store/FullStoreDownloadPhase.swift)
- [App/Store/FullStoreDownloadProgress.swift](../../../Sources/ChineseCalendarUI/App/Store/FullStoreDownloadProgress.swift)
- [App/Store/FullStoreDownloadProgressViews.swift](../../../Sources/ChineseCalendarUI/App/Store/FullStoreDownloadProgressViews.swift)
- [App/Store/FullStoreDownloadStepView.swift](../../../Sources/ChineseCalendarUI/App/Store/FullStoreDownloadStepView.swift)

### Home

- [Home/CalendarHomeTabView.swift](../../../Sources/ChineseCalendarUI/Home/CalendarHomeTabView.swift)
- [Home/Navigation/CalendarPresentationNodeView.swift](../../../Sources/ChineseCalendarUI/Home/Navigation/CalendarPresentationNodeView.swift)
- [Home/Navigation/CalendarTab.swift](../../../Sources/ChineseCalendarUI/Home/Navigation/CalendarTab.swift)

### Calendar

- [Calendar/CalendarPageView.swift](../../../Sources/ChineseCalendarUI/Calendar/CalendarPageView.swift)
- [Calendar/Day/Detail/CalendarFactTile.swift](../../../Sources/ChineseCalendarUI/Calendar/Day/Detail/CalendarFactTile.swift)
- [Calendar/Day/Detail/ChineseDateExpressionSummaryView.swift](../../../Sources/ChineseCalendarUI/Calendar/Day/Detail/ChineseDateExpressionSummaryView.swift)
- [Calendar/Day/Detail/SelectedLunarDayDetail.swift](../../../Sources/ChineseCalendarUI/Calendar/Day/Detail/SelectedLunarDayDetail.swift)
- [Calendar/Day/Grid/LunarDayGrid.swift](../../../Sources/ChineseCalendarUI/Calendar/Day/Grid/LunarDayGrid.swift)
- [Calendar/Day/Grid/LunarDayGridCell.swift](../../../Sources/ChineseCalendarUI/Calendar/Day/Grid/LunarDayGridCell.swift)
- [Calendar/Month/CalendarTodayToolbar.swift](../../../Sources/ChineseCalendarUI/Calendar/Month/CalendarTodayToolbar.swift)
- [Calendar/Month/YearMonthHeader.swift](../../../Sources/ChineseCalendarUI/Calendar/Month/YearMonthHeader.swift)
- [Calendar/Year/Picker/CalendarYearPickerView.swift](../../../Sources/ChineseCalendarUI/Calendar/Year/Picker/CalendarYearPickerView.swift)
- [Calendar/Year/Picker/CalendarYearSection.swift](../../../Sources/ChineseCalendarUI/Calendar/Year/Picker/CalendarYearSection.swift)

### History

- [History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonCard.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonCard.swift)
- [History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonCell.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonCell.swift)
- [History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonView.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/BoundaryComparison/DynastyBoundaryComparisonView.swift)
- [History/DynastyDetail/BoundaryComparison/DynastyBoundarySourceDetailsView.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/BoundaryComparison/DynastyBoundarySourceDetailsView.swift)
- [History/DynastyDetail/DynastyDetailView.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/DynastyDetailView.swift)
- [History/DynastyDetail/EmperorSummaryRow.swift](../../../Sources/ChineseCalendarUI/History/DynastyDetail/EmperorSummaryRow.swift)
- [History/DynastySpan/DynastyBoundarySummaryCard.swift](../../../Sources/ChineseCalendarUI/History/DynastySpan/DynastyBoundarySummaryCard.swift)
- [History/DynastySpan/DynastySpanDetailView.swift](../../../Sources/ChineseCalendarUI/History/DynastySpan/DynastySpanDetailView.swift)
- [History/EmperorDetail/EmperorDetailView.swift](../../../Sources/ChineseCalendarUI/History/EmperorDetail/EmperorDetailView.swift)
- [History/EmperorList/EmperorListView.swift](../../../Sources/ChineseCalendarUI/History/EmperorList/EmperorListView.swift)
- [History/ReignEraDetail/ReignEraBoundaryCard.swift](../../../Sources/ChineseCalendarUI/History/ReignEraDetail/ReignEraBoundaryCard.swift)
- [History/ReignEraDetail/ReignEraDetailView.swift](../../../Sources/ChineseCalendarUI/History/ReignEraDetail/ReignEraDetailView.swift)
- [History/ReignEraList/ReignEraListView.swift](../../../Sources/ChineseCalendarUI/History/ReignEraList/ReignEraListView.swift)
- [History/Shared/EmperorCard.swift](../../../Sources/ChineseCalendarUI/History/Shared/EmperorCard.swift)
- [History/Shared/Formatting/HistoryDateRangeFormatter.swift](../../../Sources/ChineseCalendarUI/History/Shared/Formatting/HistoryDateRangeFormatter.swift)
- [History/Shared/Models/DynastyCardModel.swift](../../../Sources/ChineseCalendarUI/History/Shared/Models/DynastyCardModel.swift)
- [History/Shared/Models/EmperorCardModel.swift](../../../Sources/ChineseCalendarUI/History/Shared/Models/EmperorCardModel.swift)
- [History/Shared/Models/HistoryBoundaryEvent.swift](../../../Sources/ChineseCalendarUI/History/Shared/Models/HistoryBoundaryEvent.swift)
- [History/Shared/Models/HistoryBoundaryEventRepository.swift](../../../Sources/ChineseCalendarUI/History/Shared/Models/HistoryBoundaryEventRepository.swift)
- [History/Shared/Models/ReignEraCardModel.swift](../../../Sources/ChineseCalendarUI/History/Shared/Models/ReignEraCardModel.swift)
- [History/Timeline/CalendarHistoryHomeView.swift](../../../Sources/ChineseCalendarUI/History/Timeline/CalendarHistoryHomeView.swift)

### Settings

- [Settings/CalendarColorSchemePreference.swift](../../../Sources/ChineseCalendarUI/Settings/CalendarColorSchemePreference.swift)
- [Settings/CalendarSettingsView.swift](../../../Sources/ChineseCalendarUI/Settings/CalendarSettingsView.swift)

### PreviewSupport

- [PreviewSupport/FullStoreDownloadPreview.swift](../../../Sources/ChineseCalendarUI/PreviewSupport/FullStoreDownloadPreview.swift)

### 下层与资源配置

- [ChineseCalendarLocalization](../../../Sources/ChineseCalendarLocalization/README.md)：统一持有全部文案定义、`Calendar` 资源表和 bundle，仅依赖 Foundation。
- [LunarCalendarFormatting](../../../Sources/ChineseCalendarCore/LunarCalendarFormatting.swift)：年、月、日产品句式调用基础本地化模块；公历日期格式仍使用指定 locale 的 Foundation FormatStyle。
- [Package.swift](../../../Sources/Package.swift)：默认语言为 `zh-Hans`，Core/UI 显式依赖 Localization，catalog 只由 Localization 处理。
- [CalendarDatePrecisionPresentation](../../../Sources/ChineseCalendarUI/Localization/CalendarDatePrecisionPresentation.swift)：数据模型日期精度到资源的映射保留在 UI。
- [SeededModelContainer](../../../Sources/ChineseCalendarPersistence/SeededModelContainer.swift)：将既有错误类型公开给 UI 做类型化映射；不引入 UI 依赖。
- [CalendarStoreErrorPresentation](../../../Sources/ChineseCalendarUI/App/Store/CalendarStoreErrorPresentation.swift)：下载清单、版本、校验、HTTP、网络、权限/磁盘及未知错误提示。底层英文说明保留作诊断，界面不再透传。

## 明确保留的字面量

| 类别 | 位置/示例 | 保留理由 |
| --- | --- | --- |
| 历法领域值 | Core 的天干地支、`正月`、`初一`、`闰`/`后`、`大`/`小`；Data 的等价历法模型 | 这些是中国历自身的名称与值，不是围绕数据拼接的界面句式。`chineseName` 的固定中文语义不变。 |
| 外部实体与原文 | `Dynasty.name`、`Emperor.displayName`、`ReignEra.name`、日期 `sourceText` 与来源 note | 保持数据源与历史原文；标签、摘要、前后缀已迁移。 |
| 技术标识 | DeepLink scheme/path/query、destination ID、storeIdentity、AppStorage key、默认正统传统 ID、事件 ID | 参与路由、查找或持久化，不展示为产品文字，不能随语言变化。 |
| 导入来源协议 | `HistoryNoteFormatter` 的 `Parsed from `、`; source note: ` | 用于提取来源备注的解析标记，不是界面文案。 |
| 数值和空布局值 | 纯数字插值、皇帝序号的两位显示、条件性空 unit | 没有可翻译的词语或句式；带单位、纪元、数量语义的完整模板均已迁移。 |
| 诊断与断言 | Core 的 precondition、Persistence 的 LocalizedError、各模块 OSLog | 日志/开发工具使用；UI 捕获错误后转为资源提示。 |
| 开发者 Preview 与测试样本 | `#Preview` 标题、fixture/entity 示例、测试预期值 | 不进入运行时产品流程。`FullStoreDownloadPreview` 可从设置打开，因此已全量迁移，不适用此例外。 |
| App 产品专名 | `project.yml`/Info.plist 中的 `Chinese Calendar` | 平台元数据中的产品专名，不是业务 View 的可翻译模板。 |

## 扫描与边界

`python3 Scripts/validate_localized_copy.py` 检查两个 catalog 的所有定义与生产 UI 字符串（包括英文和插值），技术例外显式列在脚本中。开发者 Preview、测试、来源解析与导航协议使用明确排除范围；未来在这些文件新增真实产品文案时仍需人工检查，不能用文件名规避迁移。

补充人工扫描覆盖 Core、Data、Persistence、NavigationCore、App 入口、SwiftUI 各种 title/label/help/alert、展示模型、`localizedDescription`、rawValue 和句子拼接。`#119` 年号列表空状态继续使用原来的中文与布局，定义只有 `History.ReignEraList.Empty` 一个来源。

资源以 `LocalizedStringResource` 为主；原有 String 格式接口、混合数据与可选字段的卡片摘要继续在边界解析，完整模板和列表连接统一管理。错误、下载状态、Tab、设置名称与边界事件已经保留资源直至显示。

结果和证据见 [001-result.md](001-result.md)。
