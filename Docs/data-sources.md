# 数据来源

## 目的

本文档定义首个发布版本的数据集来源，以及每类 source 各自负责的内容。
项目将以下两类 source 分开处理：

- calendar 和 date-conversion facts
- political 和 reign-era attribution

这样可以把历史 calendar logic 与 reign-era 的整理工作分离开来。

## Source Categories

### Calendar Source

Primary source：

- `https://github.com/ytliu0/ChineseCalendar`

职责：

- Chinese calendar calculation
- lunar date mapping
- leap-month information
- 如果 source 中可直接获得，或能够从其输出推导，则包括 sexagenary value
- 可被标准化为 processed artifact 的 day-level calendar facts

这个 source 不应被视为 emperor、dynasty 或 reign-era 信息的 authority。

### Reign-Era Source

Primary role：

- 提供 dynasty、emperor、reign era 以及 regnal year attribution

职责：

- dynasty 名称
- emperor identity
- reign-era 名称
- reign-era 的起止 span
- 当同一天适用多条记录时，支持 parallel regime coverage

这类 source 可以由一个或多个经过整理的 historical reference 组成。

## Source Boundary Rules

### Calendar Data Must Stay Focused

calendar ingestion 只应产出：

- absolute day mapping
- civil-date display value
- lunar date value
- sexagenary value

它不应负责分配 dynasty 或 emperor。

### Reign-Era Data Must Stay Focused

reign-era ingestion 只应产出：

- dynasty
- emperor
- reign era
- day-to-era assignment span

它不应重新计算 lunar date 或 civil date。

### Merge Only in the Processed Layer

只有在两类 source 都完成标准化后，app 才应进行 merge。

这个 merge step 应：

- 让两类 source 对齐到同一套 day index
- 保留 one-to-many 的 reign-era assignment
- 避免修改原始 raw file

## Storage Layout

建议的 repository layout：

- `Data/Raw/ChineseCalendar`：upstream clone 或提取后的 raw source file
- `Data/Raw/ReignEras`：手工整理的 reign-era source material
- `Data/Processed/calendar_days`：标准化后的 day-level calendar output
- `Data/Processed/reign_eras`：标准化后的 political output

约束建议：

- 不要把 raw historical source file 放到 app target 目录下。
- app runtime code 不应直接依赖 `Data/Raw`。
- 将 `Data/Processed` 视为进入 persistence 的 import boundary。

## Recommended Raw Formats

### Calendar Raw Data

可接受形式：

- clone 下来的 upstream repository 内容
- 从 upstream project 中提取出的表格
- 直接由 upstream source 生成的中间文件

要求：

- 保留 provenance
- 尽量保留精确的 upstream version 或 commit

### Reign-Era Raw Data

可接受形式：

- 人工整理的 CSV file
- 人工整理的 JSON file
- 带 source note 的手工维护 reference table

要求：

- dynasty、emperor、reign era 必须有稳定 ID
- 对含糊或存在争议的 span 提供清晰的 source note
- 支持 regime 并存时的 overlapping assignment

## Recommended Processed Outputs

### Calendar-Day Artifact

建议文件：

- `Data/Processed/calendar_days/calendar_days.jsonl`

每一行应包含：

- absolute day identity
- Julian day number 或等价的 anchor
- civil-date display value
- lunar date value
- sexagenary value

### Reign-Era Assignment Artifact

建议文件：

- `Data/Processed/reign_eras/reign_era_assignments.jsonl`

每一行应包含：

- absolute day identity，或可解析到 day identity 的 assignment span
- dynasty ID 和名称
- emperor ID 和名称
- reign-era ID 和名称
- regnal year number
- primary-display marker
- 并行记录的排序信息

## Source Provenance

每个 processed artifact 都应能追溯回其输入 source。

导入时建议跟踪以下 metadata：

- upstream repository URL
- upstream commit hash 或 release tag
- 本地 source file path
- importer version 或 script name
- generation timestamp

这些 metadata 可以存放在：

- `Data/Processed` 下的 sidecar metadata file
- import log
- 后续的 manifest file

## Validation Expectations

### Calendar Validation

应校验：

- day index 连续无断裂
- civil-date conversion 符合 1582 reform rule
- lunar month 和 day 落在合法范围内
- leap-month marker 与 source 一致

### Reign-Era Validation

应校验：

- 所有 foreign ID 稳定且唯一
- assignment span 能解析到合法的 day index
- regnal year number 为正数
- overlapping record 是有意为之，而不是意外重复

### Merge Validation

应校验：

- 每条 assignment 都指向真实存在的 calendar day
- summary selection rule 在每天最多只产出一条 primary assignment
- 没有 reign-era record 的日期是被有意处理，而不是被静默丢弃

## Open Questions

- 首个 authoritative 的 reign-era source 应选用哪份 historical reference？
- 我们是只维护一个人工整理 source，还是融合多份 reference 并记录冲突？
- processed output 中的 provenance 字段应内联存储，还是放在独立 manifest 中？
