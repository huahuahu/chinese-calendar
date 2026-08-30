# BuildChineseCalendarSeedStore

这个目录是把 `Data/Processed/swiftdata_import` 转成 SwiftData SQLite seed store 的脚本包。

它只负责离线生成 seed store：读取 JSONL、写入 SwiftData model、收尾 SQLite journal，并写出 runtime manifest。默认生成随 app bundle 发布的 `base` store；也可以显式生成远端发布用的 `full` store。

## 运行

生成或更新随 App 发布的 base store 时，从仓库根目录执行唯一的写入入口：

```bash
make seed-store
```

脚本先计算稳定的内容身份；已提交 manifest 的 `artifactVersion` 一致时直接退出，不以 mtime 判断。需要直接调用底层 builder（例如生成 full store）时，必须先生成 identity 文件：

```bash
identity_file="$(mktemp)"
node Scripts/BuildChineseCalendarSeedStore/seed_store_identity.mjs \
  --input Data/Processed/swiftdata_import \
  --content-level full \
  --output "$identity_file"
swift run -c release --package-path Scripts/BuildChineseCalendarSeedStore ChineseCalendarSeedStoreBuilder \
  --input Data/Processed/swiftdata_import \
  --output Data/Processed/remote_full_seed_store \
  --content-level full \
  --identity-file "$identity_file" \
  --save-interval 5000
rm -f "$identity_file"
```

普通 Xcode build 只运行 `validate_seed_store.sh`。它会校验 committed artifact，stale 时提示执行 `make seed-store`，成功时只更新 DerivedData stamp，不写仓库中的 SQLite 或 manifest。

## 工件身份

- `datasetVersion`：按稳定文件名顺序覆盖实际导入 JSONL 的 SHA-256；
- `schemaVersion`：`ChineseCalendarModelSchema.versionIdentifier`；
- `seedStoreFormatVersion`：发布格式版本；
- `seedRecipeVersion`：生成规则语义变化时显式递增；
- `artifactVersion`：上述字段与 `seedStoreContentLevel` 的组合 SHA-256。

`generatedAt`、`rawFetchedAt` 等 provenance 不参与身份计算。base identity 覆盖 builder 实际读取的全部十个 JSONL；full identity 还覆盖 `calendar_days` 下全部日级 JSONL。

## 参数

```text
--input <path>          SwiftData import JSONL 目录
--output <path>         输出的 resource bundle 目录
--content-level <level> 输出内容级别：base 或 full，默认 base
--identity-file <path>  seed_store_identity.mjs 生成的身份文件，必填
--keep-output           不删除整个 output 目录，只清理旧 SQLite store 文件
--save-interval <count> 每导入多少条日数据保存一次，必须为正整数
--help                  打印帮助
```

`base` store 会导入 schema、农历年、农历月、朝代和正统数据，但跳过 `CalendarDay`、`CivilDate`、`ChineseLunarDay` 日级数据。`full` store 会导入全部数据，适合压缩后发布到远端。

默认会先删除 output 目录，再重新生成。使用 `--keep-output` 时，脚本仍会删除旧的：

```text
ChineseCalendar.sqlite
ChineseCalendar.sqlite-wal
ChineseCalendar.sqlite-shm
```

## 输入

输入目录来自 `Scripts/ImportChineseCalendar/generate_swiftdata_import.swift`：

```text
Data/Processed/swiftdata_import/
  chinese_lunar_years.jsonl
  chinese_lunar_months.jsonl
  chinese_date_expressions.jsonl
  dynasties.jsonl
  emperors.jsonl
  emperor_reign_segments.jsonl
  reign_eras.jsonl
  dynasty_source_audit.json
  orthodox_traditions.jsonl
  orthodox_boundaries.jsonl
  orthodox_periods.jsonl
  calendar_days/<civil-year>/calendar_days.jsonl
  manifest.json
```

导入顺序固定为：

1. `ChineseLunarYear`
2. `ChineseLunarMonth`
3. `CalendarDay` + `CivilDate` + `ChineseLunarDay`
4. `ChineseDateExpression`
5. `Dynasty`
6. `Emperor`
7. `EmperorReignSegment`
8. `ReignEra`
9. `OrthodoxTradition`
10. `OrthodoxBoundary`
11. `OrthodoxPeriod`

`full` 模式下，日数据按 civil year 分目录读取，并按目录名数字升序导入。`base` 模式会跳过第 3 步，但仍会导入农历年、农历月、朝代和正统时期数据。

## 输出

脚本输出：

```text
Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/
  ChineseCalendar.sqlite
  manifest.json
```

`Data/Processed/swiftdata_import/manifest.json` 是导入目录和计数 manifest；完整朝代来源审计信息保存在同目录的 `dynasty_source_audit.json`。输出到 app resource bundle 的 `manifest.json` 是精简 runtime manifest，只保留安装、版本、覆盖范围、row count 和少量来源摘要。运行时朝代数据以 SQLite 里的 `Dynasty` / `OrthodoxPeriod` 等 SwiftData 表为准，不再在 manifest 中重复保存解析明细。

生成结束后，脚本会执行：

```sql
PRAGMA wal_checkpoint(TRUNCATE);
DELETE FROM ACHANGE;
DELETE FROM ATRANSACTION;
DELETE FROM ATRANSACTIONSTRING;
VACUUM;
PRAGMA journal_mode=DELETE;
```

然后删除 `ChineseCalendar.sqlite-wal` 和 `ChineseCalendar.sqlite-shm`。这会保留 SwiftData/Core Data 需要的内部表结构，但清空构建导入阶段产生的 transaction-history 行。最终 bundle 里应该只有一个 SQLite 主文件和 manifest。

## 正确性检查

生成后可以先检查文件是否干净：

```bash
find Apps/Shared/Resources/ChineseCalendarSeedStore.bundle -maxdepth 1 \
  \( -name 'ChineseCalendar.sqlite*' -o -name 'manifest.json' \) -print | sort
```

期望输出：

```text
Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/ChineseCalendar.sqlite
Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/manifest.json
```

检查 SQLite journal 和完整性：

```bash
sqlite3 Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/ChineseCalendar.sqlite \
  'PRAGMA journal_mode; PRAGMA integrity_check;'
```

期望输出：

```text
delete
ok
```

检查当前完整数据集的 row count：

```bash
sqlite3 Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/ChineseCalendar.sqlite "
select 'CalendarDay', count(*) from ZCALENDARDAY union all
select 'CivilDate', count(*) from ZCIVILDATE union all
select 'ChineseLunarDay', count(*) from ZCHINESELUNARDAY union all
select 'ChineseLunarMonth', count(*) from ZCHINESELUNARMONTH union all
select 'ChineseLunarYear', count(*) from ZCHINESELUNARYEAR;
"
```

当前完整数据集期望为：

```text
CalendarDay|884256
CivilDate|884256
ChineseLunarDay|884256
ChineseLunarMonth|29944
ChineseLunarYear|2421
```

base store 期望为：

```text
CalendarDay|0
CivilDate|0
ChineseLunarDay|0
ChineseLunarMonth|29944
ChineseLunarYear|2421
```

一个快速抽样查询：

```bash
sqlite3 Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/ChineseCalendar.sqlite "
select cd.ZYEAR || '-' || cd.ZMONTH || '-' || cd.ZDAYOFMONTH,
       ld.ZLUNARMONTHINDEX,
       ld.ZDAYNUMBERINMONTH
from ZCIVILDATE cd
join ZCALENDARDAY day on day.ZCIVILDATE = cd.Z_PK
join ZCHINESELUNARDAY ld on day.ZCHINESELUNARDAY = ld.Z_PK
where cd.ZYEAR = 2024 and cd.ZMONTH = 1 and cd.ZDAYOFMONTH = 1;
"
```

期望输出：

```text
2024-1-1|27754|20
```

## 常见问题

- 如果脚本包编译时没有识别到 `ChineseCalendarPersistence` 的新文件，先删除 `Scripts/BuildChineseCalendarSeedStore/.build` 再重跑。
- 如果 row count 不一致，先重新生成 `Data/Processed/swiftdata_import`，再重新运行本脚本。
- 如果出现 WAL/SHM 文件，重新运行脚本；它的 finalize 阶段会 checkpoint、切换到 DELETE journal，并清理 sidecar 文件。
