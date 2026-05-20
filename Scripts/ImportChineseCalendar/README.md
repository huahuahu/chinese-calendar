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
- 农历月长度为 29 或 30，已知例外写入 manifest
- 农历年月份数量在 v1 预期范围内

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
