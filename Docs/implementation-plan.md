# 实施计划

## 产品目标

构建一个共享 iOS 与 macOS 代码的 app，用于按日浏览中国历史历法。
首个发布版本聚焦于秦朝及之后的日期。

用户应能够沿着连续的 civil-date timeline 浏览，并查看单日详情。
每一天应展示：

- Civil date
- 该 civil date 属于 Julian 还是 Gregorian
- Lunar year、month、day
- 该 lunar month 是否为 leap month
- Sexagenary year、month、day
- Dynasty
- Emperor
- Reign era
- 以中文历史格式显示的 regnal year，例如 `元年`、`二年`、`三年`

app 必须支持同一天存在多条并行 regime record。

## 首个发布版本的决策

### Date Range

- 支持范围从秦朝开始。

### Civil Calendar Rule

- 内部使用连续的 day index 进行排序和查找。
- 在 Gregorian reform 之前，civil date 使用 Julian calendar 显示。
- 按 1582 reform boundary 进行切换。

### Navigation Model

- 首页应以连续的 civil date 进行浏览。
- Chinese calendar data 仍然是 primary content。
- civil date 作为 navigation coordinate。

### Data Sources

- calendar calculation 和 source data 来自 `ytliu0/ChineseCalendar`。
- reign-era data 作为独立 source 维护。
- raw source file 必须放在 app target 之外。

### Persistence Strategy

- app 的 query model 使用 SwiftData 存储。
- 不要让 SwiftData model 直接耦合 raw upstream file format。
- 先将 processed data artifact 导入 SwiftData。

## Repository Layout

保持 source data 与 app code 分离。

- `Data/Raw/ChineseCalendar`：upstream raw calendar data
- `Data/Raw/ReignEras`：raw reign-era source material
- `Data/Processed/calendar_days`：标准化后的 day-level calendar artifact
- `Data/Processed/reign_eras`：标准化后的 reign-era artifact
- `Scripts/ImportChineseCalendar`：导入 upstream calendar 的脚本
- `Scripts/ImportReignEras`：导入 reign-era 的脚本
- `Scripts/BuildDataset`：将 processed artifact 合并为 app import payload 的脚本

## 建议的模块结构

- `ChineseCalendarCore`：不依赖 SwiftData 的 domain type 与 formatting rule
- `ChineseCalendarData`：import pipeline、repository、parsing 与 query service
- `ChineseCalendarPersistence`：SwiftData model 与 persistence service
- `ChineseCalendarUI`：共享的 SwiftUI view 与 navigation
- `Apps/iOSApp`：iOS 专用 app setup
- `Apps/macOSApp`：macOS 专用 app setup

## SwiftData Model Outline

### CalendarDay

每个 absolute day 一行。

- `id`
- `dayIndex`
- `julianDayNumber`

### CivilDateRecord

面向显示的 civil date metadata。

- `calendarDayID`
- `year`
- `month`
- `day`
- `calendarStyle`（`julian` 或 `gregorian`）

### LunarDateRecord

- `calendarDayID`
- `lunarYear`
- `lunarMonth`
- `lunarDay`
- `isLeapMonth`

### GanzhiRecord

- `calendarDayID`
- `yearStem`
- `yearBranch`
- `monthStem`
- `monthBranch`
- `dayStem`
- `dayBranch`

### Dynasty

- `id`
- `name`
- `startDayIndex`
- `endDayIndex`

### Emperor

- `id`
- `name`
- `templeName`
- `posthumousTitle`
- `dynastyID`

### ReignEra

- `id`
- `name`
- `emperorID`
- `startDayIndex`
- `endDayIndex`

### ReignEraAssignment

将一天映射到一条或多条 political record。

- `calendarDayID`
- `dynastyID`
- `emperorID`
- `reignEraID`
- `regnalYearNumber`
- `displayOrder`
- `isPrimary`

## Processed Data Format

在导入 SwiftData 之前，先使用标准化的 intermediate artifact。

建议文件：

- `Data/Processed/calendar_days/calendar_days.jsonl`
- `Data/Processed/reign_eras/reign_era_assignments.jsonl`

processed layer 应承担：

- 将 import script 与 app persistence 解耦
- 让 validation 和 snapshot test 更容易落地
- 便于后续替换或改进 reign-era source

## First UI Slice

### Home Timeline

- 按连续 civil date 浏览
- 显示当前 civil date，并标注 Julian 或 Gregorian
- 显示 lunar date 摘要
- 显示 sexagenary 摘要
- 显示 primary reign-era record
- 支持前一天和后一天切换
- 支持跳转到指定 civil date

### Day Detail

- 显示完整的 civil-date presentation
- 显示 lunar date 与 leap-month flag
- 显示 sexagenary year、month、day
- 显示该日全部 reign-era assignment

## 建议的交付顺序

1. 新增 `ChineseCalendarPersistence` target。
2. 定义 SwiftData entity。
3. 先做一个 in-memory prototype，用于 timeline 和 day detail view。
4. 定义 processed-data schema。
5. 实现 calendar data 的导入脚本。
6. 实现 reign-era data 的导入脚本。
7. 将 processed artifact 导入 SwiftData。
8. 用真实 query 替换 placeholder repository。

## Open Questions

- 首个发布版本中，哪份 reign-era reference source 应被视为 authoritative？
- `templeName` 和 `posthumousTitle` 在 v1 中应对每位 emperor 强制要求，还是保持 optional？
- 首个发布版本是否应支持按 reign-era 名称搜索，还是只支持 timeline browsing？
- 当前数据集支持的最小和最大日期边界应如何定义？
