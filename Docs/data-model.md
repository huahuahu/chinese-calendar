# 数据模型

## 目的

本文档定义 Chinese calendar app 首个发布版本的数据模型。
它将以下概念分离：

- absolute day identity
- civil-date presentation
- Chinese calendar facts
- political and reign-era attribution

目标是在保持导入流水线与 app persistence 松耦合的前提下，支持从秦朝开始的、按日准确浏览。

## 建模原则

### One Absolute Day, Many Representations

即使同一天存在多层展示信息，app 也应将这一天视为一条唯一的 absolute record。

每一天可以包含：

- 一条 civil-date presentation
- 一条 lunar-date record
- 一条 sexagenary record
- 多条 reign-era assignment

### Civil Date Is a Navigation Coordinate

app 以 civil date 进行浏览，但 civil date 不是 identity 的 source of truth。

- 内部 identity 应使用连续的 day index。
- civil date 用于显示和用户导航。
- civil date 的显示应在 1582 reform boundary 处从 Julian 切换到 Gregorian。

### Political Attribution Is One-to-Many

同一天在特殊情况下可能同时属于多个并行的 political timeline。

- 一天在特殊情况下可能映射到多个 dynasty 或 regime。
- 根据所选 source data，一天可能对应多个 emperor 或 reign era。
- 其中一条 assignment 应标记为 primary record，用于 summary UI。

## 实体概览

## CalendarDay

表示数据集中的一个 absolute day。

建议字段：

- `id: UUID`
- `dayIndex: Int`
- `julianDayNumber: Int`

职责：

- 作为存储层中一天的主 identity
- 用于排序和 timeline traversal
- 作为相关记录的 anchor point

说明：

- `dayIndex` 应在整个支持范围内保持连续。
- `julianDayNumber` 可用于与导入的 source data 以及外部计算进行交叉校验。

## CivilDateRecord

表示某一天对应的 civil-date display。

建议字段：

- `id: UUID`
- `calendarDayID: UUID`
- `year: Int`
- `month: Int`
- `day: Int`
- `calendarStyle: CivilCalendarStyle`

建议 enum：

- `julian`
- `gregorian`

职责：

- 驱动 timeline label 和 date-jump UI
- 在数据层明确表达 1582 reform rule

说明：

- 首个发布版本中，每天只预期存在一条 civil-date record。
- 该 record 应在应用所选 reform boundary 后生成。

## LunarDateRecord

表示附着在某个 absolute day 上的 Chinese lunar date。

建议字段：

- `id: UUID`
- `calendarDayID: UUID`
- `lunarYear: Int`
- `lunarMonth: Int`
- `lunarDay: Int`
- `isLeapMonth: Bool`

为方便使用可选的派生字段：

- `monthDisplayName: String`
- `dayDisplayName: String`

职责：

- 存储标准化后的 lunar date facts
- 支持详情展示和未来的搜索能力

说明：

- 即使也生成 display string，仍应存储标准化 numeric field。
- 在可行情况下，格式化逻辑应保留在共享 domain 或 presentation helper 中。

## GanzhiRecord

表示某一天的 sexagenary label。

建议字段：

- `id: UUID`
- `calendarDayID: UUID`
- `yearStem: String`
- `yearBranch: String`
- `monthStem: String`
- `monthBranch: String`
- `dayStem: String`
- `dayBranch: String`

职责：

- 支持显示 sexagenary year、month、day
- 让导入后的 cyclical label 保持标准化并可查询

说明：

- 将 stems 和 branches 分开存储，可以为未来筛选保留灵活性。
- 像 `甲子` 这样的组合显示字符串应由 formatting helper 生成。

## Dynasty

表示一个 dynasty，或顶层 historical regime grouping。

建议字段：

- `id: String`
- `name: String`
- `startDayIndex: Int?`
- `endDayIndex: Int?`

可选字段：

- `sortName: String`
- `notes: String?`

职责：

- 对 emperor 和 reign era 进行分组
- 在 UI 中提供易于理解的 historical context

说明：

- 如果 source material 存在不确定性，开始和结束边界可以保留为 optional。

## Emperor

表示某个 dynasty 或 regime context 中的一位 emperor。

建议字段：

- `id: String`
- `dynastyID: String`
- `name: String`
- `templeName: String?`
- `posthumousTitle: String?`
- `personalName: String?`

职责：

- 为 reign-era display 提供 ruler identity
- 为后续更丰富的历史细节留出空间

说明：

- 在 v1 中，`templeName` 和 `posthumousTitle` 应为 optional。
- primary display name 应选择在当前 source 中最容易识别的历史称谓。

## ReignEra

表示一个具名的 reign era。

建议字段：

- `id: String`
- `emperorID: String`
- `name: String`
- `startDayIndex: Int?`
- `endDayIndex: Int?`

可选字段：

- `eraSequence: Int?`

职责：

- 独立建模 reign-era identity，而不是把它直接绑在某一天的 assignment 上
- 允许在 day-level assignment record 之间复用

说明：

- 同一位 emperor 可能拥有多个 reign era。
- 起止边界有助于校验导入后的 assignment span。

## ReignEraAssignment

将某一天映射到一条 political record。

建议字段：

- `id: UUID`
- `calendarDayID: UUID`
- `dynastyID: String`
- `emperorID: String`
- `reignEraID: String`
- `regnalYearNumber: Int`
- `displayOrder: Int`
- `isPrimary: Bool`

可选字段：

- `sourceNote: String?`

职责：

- 支持同一天存在多条并行 regime record
- 决定 summary card 中显示哪一条 record
- 保留从 source material 导入的精确 political attribution

说明：

- `displayOrder` 应让 detail view 的顺序具备确定性。
- 首个发布版本应允许同一天存在多条 assignment，而不尝试强行合并争议记录。

## Relationships

建议首个发布版本采用以下 relationship：

- `CalendarDay` 到 `CivilDateRecord`：one-to-one
- `CalendarDay` 到 `LunarDateRecord`：one-to-one
- `CalendarDay` 到 `GanzhiRecord`：one-to-one
- `CalendarDay` 到 `ReignEraAssignment`：one-to-many
- `Dynasty` 到 `Emperor`：one-to-many
- `Emperor` 到 `ReignEra`：one-to-many
- `Dynasty` 到 `ReignEraAssignment`：通过 foreign key reference 建立 one-to-many
- `Emperor` 到 `ReignEraAssignment`：通过 foreign key reference 建立 one-to-many
- `ReignEra` 到 `ReignEraAssignment`：通过 foreign key reference 建立 one-to-many

## Formatting Rules

### Regnal Year Display

regnal year 在存储时使用 integer。
显示时按中国历史习惯进行格式化。

示例：

- `1` -> `元年`
- `2` -> `二年`
- `3` -> `三年`

### Civil Calendar Label

UI 应明确标注某个 civil date 属于：

- `Julian`
- `Gregorian`

这样可以避免 1582 边界附近的歧义。

### Ganzhi Display

stems 和 branches 分开存储。
显示时通过拼接二者生成最终字符串。

示例：

- `甲` + `子` -> `甲子`
- `丙` + `午` -> `丙午`

## Import Boundaries

app 不应直接将 raw source file 导入到 SwiftData。

应使用一个 processed layer，负责：

- 标准化 day identity
- 应用 civil-calendar reform rule
- 将 reign-era reference 解析为稳定 ID
- 在持久化导入前，先保证每个 absolute day 形成清晰记录

## Open Modeling Questions

- 未来版本是否应将 dynasty 与非王朝 regime 拆分成不同 entity type？
- sexagenary value 是否应在 shared domain code 中使用 enum、在 persistence 中使用 string？
- 后续是否需要为 reign-era 名称检索单独设计 search index model？
