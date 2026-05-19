# 日历数据模型

## 目的

本文档定义 Chinese calendar app 首个发布版本的数据模型，并统一说明以下几点：

- 每个 entity 的职责与字段含义
- `day -> month -> year` 的层级关系
- entity 之间的 relationship
- 常见建模问题与约定

目标是同时满足这几件事：

- 支持从秦朝开始的按日浏览
- 区分 Julian / Gregorian civil date
- 正确表达农历年、月、日的层级关系
- 正确表达年干支、月干支、日干支分别属于不同层级实体
- 与导入流水线、持久化、UI 展示保持清晰边界

## 核心原则

### 先有绝对的一天，再挂接不同表示

App 中的“一天”必须先有唯一身份，然后再关联 civil date、农历月、农历年、干支和年号信息。

- 绝对身份由 `ChineseCalendarDay.dayIndex` 承担
- `julianDayNumber` 用于与外部数据、天文算法和校验对齐
- `CivilDateRecord` 负责显示层的 civil date
- 农历层级通过 `ChineseLunarMonth` 和 `ChineseLunarYear` 组织

### 干支分属不同层级

年、月、日干支并不属于同一个 entity。

- `ChineseCalendarDay` 保存日干支
- `ChineseLunarMonth` 保存月干支
- `ChineseLunarYear` 保存年干支

因此，不应把年干支、月干支、日干支都压平为“某一天上的三个并列字段”。

### Civil Date 是导航坐标，不是主身份

用户通常通过 civil date 浏览，但内部 identity 不能依赖 civil date 文本。

- 内部排序和跳转依赖 `dayIndex`
- `CivilDateRecord` 只负责 civil date 的显示与查找
- `calendarStyle` 用来区分 Julian 和 Gregorian

## 层级总览

首个版本的主层级如下：

- `ChineseCalendarDay`：最底层的绝对“日”
- `ChineseLunarMonth`：某个具体农历年中的某个月
- `ChineseLunarYear`：某个具体农历年

辅助 entity：

- `CivilDateRecord`：某一天对应的 civil date 表示

可以把关系理解为：

- 一天 `belongs to` 一个农历月
- 一个农历月 `belongs to` 一个农历年
- 一天 `has one` civil date record

## Day 层

### `ChineseCalendarDay`

表示数据集中的一个具体历日实体。它是整个模型的最小稳定单位，也是排序、跳转、详情展示的基础。

建议把它理解为 absolute day record。

标量字段：

| 字段 | 含义 |
| --- | --- |
| `dayIndex: Int` | 全数据集中的统一日序号，是一天的稳定主键，用于排序、前后跳转、跨 entity 关联。 |
| `julianDayNumber: Int` | 这一天对应的儒略日数，用于与外部数据源、换算逻辑和校验对齐。 |
| `dayStem: String` | 这一天日干支中的“天干”部分。 |
| `dayBranch: String` | 这一天日干支中的“地支”部分。 |
| `lunarDayRawValue: Int` | 这一天在所属农历月中的日序，例如初一、初二、十五、三十。它只在“月内”有意义，不是全局唯一键。 |

关系字段：

| 字段 | 含义 |
| --- | --- |
| `chineseLunarMonth: ChineseLunarMonth?` | 这一天所属的农历月。逻辑上应存在，存储上允许在导入中间态暂时为空。 |
| `civilDateRecord: CivilDateRecord?` | 这一天对应的 civil date 记录。首个版本中预期是一对一。 |

计算属性：

- `dayStemBranch`：把 `dayStem + dayBranch` 组合成完整日干支
- `lunarDay`：把 `lunarDayRawValue` 还原为类型安全的 `LunarDay`

职责：

- 作为“一天”的唯一身份
- 支持时间轴排序、定位、前后跳转
- 保存日级别信息，例如日干支、月内日序
- 连接 civil date、农历月、年号等上层信息

### `CivilDateRecord`

表示某个 `ChineseCalendarDay` 在 civil calendar 中的显示结果。它不是独立的“绝对一天”，而是 day entity 的一种导航和展示视图。

标量字段：

| 字段 | 含义 |
| --- | --- |
| `dayIndex: Int` | 指回 `ChineseCalendarDay.dayIndex` 的外键，用来说明这条 civil date 属于哪一天。 |
| `year: Int` | civil calendar 中的年份。 |
| `month: Int` | civil calendar 中的月份。 |
| `day: Int` | civil calendar 中的日。 |
| `calendarStyle: CivilCalendarStyle` | 这条 civil date 使用 `julian` 还是 `gregorian`。 |

职责：

- 驱动 civil date 显示
- 支持从 civil date 反查 `ChineseCalendarDay`
- 明确 1582 reform boundary 以及后续显示口径

约定：

- 首个版本中，每个 `ChineseCalendarDay` 只应有一条 `CivilDateRecord`
- `CivilDateRecord` 不承担 day identity，它只引用已有的 `dayIndex`

## Month 层

### `ChineseLunarMonth`

表示一个具体的农历月，而不是抽象的“正月”或“二月”概念。因为同样的月份编号会在不同农历年中重复出现，所以月份必须建模为实体。

标量字段：

| 字段 | 含义 |
| --- | --- |
| `id: Int` | 该农历月的稳定唯一标识，作为内部主键使用。 |
| `monthNumberRawValue: Int` | 月份编号，对应 `LunarMonthNumber.rawValue`。 |
| `isLeapMonth: Bool` | 标记这个月是否为闰月。 |
| `monthStem: String` | 该月月干支中的“天干”部分。 |
| `monthBranch: String` | 该月月干支中的“地支”部分。 |

关系字段：

| 字段 | 含义 |
| --- | --- |
| `chineseLunarYear: ChineseLunarYear?` | 该月所属的农历年对象。 |
| `days: [ChineseCalendarDay]` | 该月包含的全部日期记录，是 month 到 day 的一对多关系。 |

计算属性：

- `monthStemBranch`：把 `monthStem + monthBranch` 组合成完整月干支
- `lunarMonth`：把 `monthNumberRawValue + isLeapMonth` 还原为类型安全的 `LunarMonth`

职责：

- 作为 day 与 year 之间的中间层级
- 保存月级别信息，例如月干支、闰月标记
- 表示某个月覆盖的 day range

说明：

- `monthNumberRawValue` 本身不是唯一键，因为不同年份都会有“正月、二月、三月”
- `isLeapMonth` 必须和 `monthNumberRawValue` 一起看，才能区分普通月与闰月
- 逻辑模型只保留 `chineseLunarYear` 关系，不单独定义 `chineseLunarYearID`
- 如果后续为了范围查询或统计优化，需要缓存 month / year 的覆盖区间，可以再引入派生字段；首个版本不把这类缓存字段视为核心模型的一部分。

## Year 层

### `ChineseLunarYear`

表示一个具体的农历年，而不是抽象的“某种农历年类型”。

标量字段：

| 字段 | 含义 |
| --- | --- |
| `id: Int` | 该农历年的稳定唯一标识，作为内部主键使用。 |
| `lunarYearNumber: Int` | 农历年份数字，例如 `2024`。 |
| `yearStem: String` | 该年年干支中的“天干”部分。 |
| `yearBranch: String` | 该年年干支中的“地支”部分。 |

关系字段：

| 字段 | 含义 |
| --- | --- |
| `months: [ChineseLunarMonth]` | 该年包含的全部农历月，是 year 到 month 的一对多关系。 |

计算属性：

- `yearStemBranch`：把 `yearStem + yearBranch` 组合成完整年干支

职责：

- 作为 month 层的上层容器
- 保存年级别信息，例如年干支和年份范围
- 提供农历年视角的浏览和聚合能力

说明：

- 年干支属于 `ChineseLunarYear`，不属于 `ChineseCalendarDay`
- 农历年并不总是固定 12 个月；有闰月时可能是 13 个月
- year 覆盖的日期范围可以通过其 `months` 下的实际 `days` 推导，不要求单独冗余存储边界字段。

## Relationships

### 主体关系

| From | To | Cardinality | 含义 |
| --- | --- | --- | --- |
| `ChineseLunarYear` | `ChineseLunarMonth` | one-to-many | 一个农历年包含多个农历月。 |
| `ChineseLunarMonth` | `ChineseCalendarDay` | one-to-many | 一个农历月包含多天。 |
| `ChineseCalendarDay` | `CivilDateRecord` | one-to-one | 一天对应一条 civil date 记录。 |

### 反向理解

- 一个 `ChineseCalendarDay` 只属于一个 `ChineseLunarMonth`
- 一个 `ChineseLunarMonth` 只属于一个 `ChineseLunarYear`
- 一个 `CivilDateRecord` 只描述一个 `ChineseCalendarDay`

### 在持久化层的落地方式

- `ChineseLunarYear.months` 是 year 到 month 的集合关系
- `ChineseLunarMonth.chineseLunarYear` 是 month 到 year 的对象引用
- `ChineseLunarMonth.days` 是 month 到 day 的集合关系
- `ChineseCalendarDay.chineseLunarMonth` 是 day 到 month 的对象引用
- `ChineseCalendarDay.civilDateRecord` 是 day 到 civil date 的一对一引用

如果底层存储需要额外外键列，可以作为实现细节补充，但不属于这里的逻辑模型主表达。

### 删除规则

建议使用 cascade 删除规则，意味着：

- 删除一个 year，会级联删除其 months
- 删除一个 month，会级联删除其 days
- 删除一个 day，会级联删除其 `CivilDateRecord` 和相关 `ReignEraAssignment`

这符合“上层容器拥有下层数据”的建模方式，但也要求 importer 和持久化逻辑避免误删根对象。

## 与 `ChineseCalendarDate` 的映射

[`ChineseCalendarDate.swift`](/Users/tigerguo/git/Chinese-date/Sources/ChineseCalendarCore/ChineseCalendarDate.swift) 可以看作从持久化模型拼装出的轻量读模型。

映射关系：

- `gregorianDate` 来自 `CivilDateRecord`
- `lunarYear` 来自 `ChineseLunarYear.lunarYearNumber`
- `lunarMonth` 来自 `ChineseLunarMonth.lunarMonth`
- `lunarDay` 来自 `ChineseCalendarDay.lunarDay`

这意味着：

- `ChineseCalendarDate` 适合作为 repository 的返回结果
- 它不需要直接承载全部 relationship
- 真正的 source of truth 仍是 year / month / day / civil-date 这套 entity 关系

## 典型查询路径

### 从农历日期定位到 civil date

典型条件：

- `ChineseLunarYear.lunarYearNumber`
- `ChineseLunarMonth.monthNumberRawValue`
- `ChineseLunarMonth.isLeapMonth`
- `ChineseCalendarDay.lunarDayRawValue`

查询路径：

- `ChineseLunarYear -> ChineseLunarMonth -> ChineseCalendarDay -> CivilDateRecord`

### 从 civil date 定位到农历日期

典型条件：

- `CivilDateRecord.year`
- `CivilDateRecord.month`
- `CivilDateRecord.day`
- `CivilDateRecord.calendarStyle`

查询路径：

- `CivilDateRecord -> ChineseCalendarDay -> ChineseLunarMonth -> ChineseLunarYear`

### 统计某个农历年有多少个月

查询思路：

- 统计该 `ChineseLunarYear` 下实际存在的 `months` 数量

说明：

- 普通年通常有 12 个月
- 有闰月时可能有 13 个月
- 不应在代码里写死为 12

### 统计某个农历年有多少天

查询思路：

- 统计该年覆盖的所有 `ChineseCalendarDay`

说明：

- 应基于实际数据计数，不应根据常见年份长度做估算

## Import Boundaries

App 不应直接把 raw source file 导入到持久化层。

应通过 processed layer 先完成：

- 标准化 `dayIndex`
- 对齐 `julianDayNumber`
- 应用 civil calendar reform rule
- 建立 `ChineseLunarYear` / `ChineseLunarMonth` / `ChineseCalendarDay` / `CivilDateRecord` 之间的关系
- 将 `ReignEraAssignment` 解析为稳定 ID 引用

## 常见问题

### 为什么 day 是最底层的 source of truth？

因为 app 的核心交互是“按天浏览”。只有先把每一天做成稳定实体，month、year、civil date、年号等信息才能可靠地挂接上去。`dayIndex` 也是整个数据集最适合做排序和跳转的键。

### 为什么不能只存一个扁平的 `ChineseCalendarDate`？

因为扁平结构很难准确表达“年干支属于年、月干支属于月、日干支属于日”这种层级语义，也不利于表示闰月、月份范围、年份范围和未来的年号关系。`ChineseCalendarDate` 更适合作为读模型，而不是持久化 source of truth。

### 为什么 `CivilDateRecord` 不直接当作主实体？

因为 civil date 是展示口径，不是绝对 identity。历史上还会遇到 Julian / Gregorian 的切换问题，同一个浏览系统需要先有稳定的 absolute day，再决定如何显示 civil date。

### 为什么 month 和 year 都要有自己的 `id`？

因为 `lunarYearNumber` 和 `monthNumberRawValue` 只能表达“这是哪一年、哪一月”，但不一定足够作为稳定持久化标识。显式 `id` 更适合作为内部主键，也更方便导入、去重和建立关系。

### 为什么这里把 `id` 设计成 `Int`？

因为这里把 year 和 month 视为内部实体，而不是对外暴露的业务编号。`Int` 更轻量，也更适合作为数据库主键。真正有业务语义的仍然是 `lunarYearNumber`、`monthNumberRawValue`、`isLeapMonth` 和 day range。

### 为什么 month 不再同时保留 `chineseLunarYearID` 和 `chineseLunarYear`？

文档层先只保留关系字段，避免同一层模型里重复表达两次相同语义。是否在物理存储里落成单独外键列，属于实现细节，可以由代码层决定。

### `lunarDayRawValue` 为什么不做全局唯一？

因为它表达的是“月内第几天”，每个月都会从 1 重新开始。全局唯一身份已经由 `dayIndex` 承担，所以 `lunarDayRawValue` 只负责领域语义。

### 为什么当前不保留 `startCalendarDayIndex` / `endCalendarDayIndex`？

因为它们更像可推导的范围缓存，而不是核心语义字段。month 的覆盖范围可以从 `days` 推导，year 的覆盖范围可以从其 `months` 下的 `days` 推导。只有在后续出现明确的性能需求时，再把它们作为派生缓存字段补回去会更合适。

### 为什么去掉 `Instance` 后缀？

因为这里的上下文已经明确在讨论“持久化实体”，再额外加 `Instance` 会让名字偏长、阅读负担更重。`ChineseLunarMonth` / `ChineseLunarYear` 已经足够表达这是具体存在于数据集中的实体。

### 一个日期会不会对应多个年号？

会，所以 `ChineseCalendarDay` 到 `ReignEraAssignment` 是一对多。文档这次重点讨论 calendar 主模型，但历史政治信息已经为多 assignment 场景留出了空间。

## Open Modeling Questions

- `ChineseCalendarDay` 是否需要额外的只读缓存字段来加速首页查询？
- `ChineseLunarYear.id` 与 `ChineseLunarMonth.id` 的分配规则应如何设计？
- 首个发布版本是否需要单独的 read model 来为时间轴做预聚合？
