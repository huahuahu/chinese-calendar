# ImportChineseCalendar

这个目录放从 `ytliu0/ChineseCalendar` 导入和校验日历数据的脚本。

## 生成 calendar_days

默认生成 `-220...2200` 的 civil year，每年一个 JSONL：

```bash
Scripts/ImportChineseCalendar/generate_calendar_days.swift --start-year -220 --end-year 2200
```

常用参数：

```bash
--raw-source Data/Raw/ChineseCalendar
--output Data/Processed/calendar_days
--force-refresh
--validate-only
```

生成器会读取或下载上游源码到 `Data/Raw/ChineseCalendar`，并固定使用 commit：

```text
d6aae82b63b79a6f8659ea3e064024b7d8ac3077
```

输出布局：

```text
Data/Processed/calendar_days/<year>/calendar_days.jsonl
Data/Processed/calendar_days/manifest.json
```

每行是一条 absolute day record，字段遵循 `Docs/data-model-calendar.md` 的 Processed Artifact 建议。
其中 `lunarMonth.dayCount` 保存农历月大小：`29` 为小月，`30` 为大月。

## 校验已生成数据

结构校验：

```bash
Scripts/ImportChineseCalendar/generate_calendar_days.swift --validate-only --start-year -220 --end-year 2200
```

校验内容包括：

- `dayIndex` 连续
- `julianDayNumber` 连续
- `lunarMonthIndex` 连续
- 干支 index 范围合法
- 农历日为 `1...30`
- `lunarMonth.dayCount` 为 29 或 30，且农历日不超过该月 `dayCount`
- 农历月实际日记录数与 `dayCount` 一致，已知例外写入 manifest
- 农历年月份数量在 v1 预期范围内

## 生成 SwiftData 导入文件

如果已经有 `calendar_days` JSONL，可以把它转换成和 `ChineseCalendarPersistence` 中 SwiftData
model 一一对应的导入文件：

```bash
Scripts/ImportChineseCalendar/generate_swiftdata_import.swift \
  --input Data/Processed/calendar_days \
  --output Data/Processed/swiftdata_import
```

也可以直接指向另一份工作区里的已生成数据：

```bash
Scripts/ImportChineseCalendar/generate_swiftdata_import.swift \
  --input /Users/tigerguo/git/Chinese-date/Data/Processed/calendar_days
```

输出布局：

```text
Data/Processed/swiftdata_import/chinese_lunar_years.jsonl
Data/Processed/swiftdata_import/chinese_lunar_months.jsonl
Data/Processed/swiftdata_import/calendar_days/<year>/calendar_days.jsonl
Data/Processed/swiftdata_import/manifest.json
```

这些文件是面向导入器的中间格式，不是 SwiftData store 文件。农历年和农历月是全局去重表；
每天的数据按 civil year 分片，每一行同时包含 `CalendarDay`、`CivilDate`、`ChineseLunarDay`
三个 model 的字段，方便导入器按年批处理并在同一行内建立日级关系。

建议导入顺序遵循 `manifest.json` 里的 `importOrder`：

1. `ChineseLunarYear`
2. `ChineseLunarMonth`
3. `CalendarDayBundleByCivilYear`

单条日记录形状：

```json
{
  "calendarDay": { "dayIndex": 819608, "julianDayNumber": 2460311 },
  "civilDate": { "dayIndex": 819608, "year": 2024, "month": 1, "dayOfMonth": 1, "calendarStyle": "gregorian" },
  "chineseLunarDay": { "dayIndex": 819608, "lunarMonthIndex": 27754, "dayNumberInMonth": 20, "dayStemIndex": 0, "dayBranchIndex": 0 }
}
```

关系通过稳定键回填：

- `ChineseLunarMonth.lunarYearNumber -> ChineseLunarYear.lunarYearNumber`
- `calendarDay.dayIndex -> civilDate.dayIndex`
- `calendarDay.dayIndex -> chineseLunarDay.dayIndex`
- `chineseLunarDay.lunarMonthIndex -> ChineseLunarMonth.lunarMonthIndex`

校验现有 SwiftData 导入文件：

```bash
Scripts/ImportChineseCalendar/generate_swiftdata_import.swift --validate-only
```

## 生成朝代和正统时期导入文件

`Docs/data-model-dynasty.md` 对应的朝代、日期表达和正统时期数据也输出到
`Data/Processed/swiftdata_import`，供 seed-store builder 与基础 calendar facts 一起导入：

```bash
Scripts/ImportChineseCalendar/generate_dynasty_periods.swift
```

常用参数：

```bash
--raw-source Data/Raw/ChineseCalendar
--output Data/Processed/swiftdata_import
--force-refresh
--validate-only
```

生成器以 `era_names_simp.html` 为朝代边界来源，并把网页缓存到
`Data/Raw/ChineseCalendar/era_names_simp.html`。如果 GitHub Pages 临时连接失败，脚本会回退到
manifest 中固定 commit 的 raw GitHub 文件；raw-data manifest 会记录实际抓取来源、时间和 SHA-256。

输出文件：

```text
Data/Processed/swiftdata_import/dynasties.jsonl
Data/Processed/swiftdata_import/chinese_date_expressions.jsonl
Data/Processed/swiftdata_import/orthodox_traditions.jsonl
Data/Processed/swiftdata_import/orthodox_boundaries.jsonl
Data/Processed/swiftdata_import/orthodox_periods.jsonl
```

`manifest.json` 的 `dynastyArtifact.sourceAudit` 记录 source audit 结论、解析精度统计和首版正统叙事分组：

```text
秦汉 -> 魏晋南朝 -> 唐五代两宋 -> 元明清
```

`Dynasty` 记录网页中有历日资料的政权/王朝，以及从网页 h3/table 拆出的具体政权。
`春秋时期`、`战国时期`、`西汉、新、更始`、`魏、蜀、吴`、`晋`、`南北朝`、`五代`、`宋` 这类时期或复合 h2 分节只进入 source audit，不作为单独政权；三国按 `魏`、`蜀汉`、`孙吴` 三个政权记录，晋按 `西晋`、`东晋` 记录，南朝按 `刘宋`、`齐`、`梁`、`陈` 记录，五代按 `后梁`、`后唐`、`后晋`、`后汉`、`后周` 记录，两宋按 `北宋`、`南宋` 记录。
`OrthodoxPeriod` 只记录正统链中的具体时期，例如秦、西汉、新、更始、东汉、魏、西晋、东晋、刘宋、齐、梁、陈、隋、唐、五代后梁后唐后晋后汉后周、北宋、南宋、元、明、清。
蜀汉、孙吴、北凉等会保留为 `Dynasty`，但不进入首版 `OrthodoxPeriod`。

校验现有朝代导入文件：

```bash
Scripts/ImportChineseCalendar/generate_dynasty_periods.swift --validate-only
```

校验内容包括日期精度字段组合、range 半开区间、基础日历索引存在性、引用完整性，以及正统时期
`sequenceIndex` 是否连续、`segmentIndex` 是否按上述分组递增。当前首版只自动解析网页中的公历年范围；超出基础日历覆盖的
边界保留为 `precision = unknown`，不会伪造成可查询的农历年索引。

## 历史样本校验

样本文件：

```text
Scripts/ImportChineseCalendar/Fixtures/calendar_day_samples.json
```

里面目前有 20 个样本，包括汉武帝登基、安史之乱爆发、1582 年 Gregorian reform、2017 闰六月、数据集边界等。

离线校验 JSONL、fixture、pinned upstream JS：

```bash
Scripts/ImportChineseCalendar/validate_calendar_day_samples.swift
```

联网交叉校验 GitHub Pages 当前网页 bundle：

```bash
Scripts/ImportChineseCalendar/validate_calendar_day_samples.swift --verify-web
```

`--verify-web` 拉取的是：

```text
https://ytliu0.github.io/ChineseCalendar/index_c.js
```

它和网页展示使用同一个打包 JS。网络偶发 TLS 失败时，脚本会通过 `curl` 重试。

## 脚本结构

- `generate_calendar_days.swift`：Swift 命令入口，转发到 Node 生成器。
- `generate_calendar_days.mjs`：真正的按年 JSONL 生成和结构校验逻辑。
- `validate_calendar_day_samples.swift`：Swift 命令入口，转发到 Node 样本校验器。
- `validate_calendar_day_samples.mjs`：读取 fixture、JSONL、上游 JS，并校验 20 个样本。

保留 Swift 入口是为了让项目命令统一；实际导入逻辑用 Node 执行上游浏览器 JS，避免手工移植历算逻辑。
