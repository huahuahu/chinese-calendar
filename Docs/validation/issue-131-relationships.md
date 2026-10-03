# Issue #131：SwiftData 关系与索引验证

验证日期：2026-10-03。基线 `6d354fa9`，schema 从 1.2.0 更新为 1.3.0。
构建环境为 Xcode 27.1 beta；运行验证使用 iOS 27.0、iPhone 18 Pro Max 模拟器。

## 模型与兼容策略

- 删除 Issue #131 指定的 8 个重复关联字段，以及 8 个重复独立 `id` 索引。
- 保留模型自身的稳定身份、`dayIndex`、月大小和各类序号。JSON/DTO 的关联键继续用于导入查找。
- 月份、农历年、正统传统、朝代、起止边界通过对象关系传给构造函数。关系存储可选时，缺失记录由校验器明确拒绝；日历定位不为缺失父关系的日生成选中状态。
- `ChineseLunarDay` 的 `dayIndex` 和「月份关系 + 月内日号」分别唯一。
- schema 不兼容或缺失的已安装 base/full 在创建容器前替换为内置 base。兼容 full 保留；旧远端 manifest 在下载 SQLite 前被拒绝。
- full 下载完成后依次验证字节数、SHA-256、SwiftData 打开和必需关系，再安装。

## 构建与自动测试

- Xcode MCP build-for-testing 成功。
- 最终运行 Persistence/UI 两个测试 target：87 个测试标识，展开参数后 **110 项通过，0 失败**。
- 包括磁盘 SQLite 的两个唯一约束/upsert、关闭重开、父关系重新归属、缺失关系、旧 manifest、base/full 安装决策、选中日、闰月/后月/跨年、历史筛选和 Preview fixture。
- `indexedPredicatesSafelyExcludeMissingParents` 同时验证 Foundation predicate 内存求值和磁盘查询，保证显式非空检查后的解包不会访问缺失父关系。
- 导入数据验证：919,377 条 JSONL 记录通过。seed identity Node 测试：3 项通过。
- SwiftFormat、严格 SwiftLint 和 `git diff --check` 通过。

最终测试摘要：`E8B0E530-6382-439D-B64D-89994B572DE7.txt`；Xcode 构建日志：`BuildProject-Log-20261003-162554.txt`。
本机原始证据在 `/tmp/chinese-calendar-issue-131/`，Xcode 原始日志在工具返回的 `ActionArtifacts/default` 目录。
可随仓库复核的 [SQLite 审计结果](issue-131/full-store-audit.json)、[SwiftData 查询结果](issue-131/full-swiftdata-results.txt) 和 [查询片段](issue-131/full-swiftdata-snippet.swift) 一并保存；在上述源码上下文中运行片段，并把 store 路径改成自己的完整库路径。

## 数据制品

| 制品 | schema | 字节数 | CalendarDay / CivilDate / ChineseLunarDay | 月 / 年 |
| --- | --- | ---: | ---: | ---: |
| 旧 base | 1.2.0 | 2,904,064 | 各 0 | 29,944 / 2,421 |
| 新 base | 1.3.0 | 2,658,304 | 各 0 | 29,944 / 2,421 |
| 旧 full | 1.2.0 | 209,993,728 | 各 884,256 | 29,944 / 2,421 |
| 新 full | 1.3.0 | 207,097,856 | 各 884,256 | 29,944 / 2,421 |

新 base artifactVersion：`da347edf57203db1e9528a66d43be48a21e0c3b4089064c1e184fac7a1a2fce6`。

新 full artifactVersion：`23d8415fdcfdf22663413fc00174aa10f5006ce6aee037fc1cf702637df9f20c`。

新 full SHA-256：`46934db2a516ab351bcdd206e26202dc3df210716bed8b948181017645cea488`。

旧 full 来自 `full-seed-store-2026.06.28`，已核对 manifest 的字节数和 SHA-256。
新 full 位于被 Git 忽略的 `Data/Processed/remote_full_seed_store`；不提交大型远端制品。

两个新 store 均通过 `PRAGMA integrity_check`，没有发布用 SQLite sidecar。9 类必需关系无缺失，正统区间与边界所属传统一致。
实际 SQLite 已无 8 个被删除字段；8 个 `id` 各只保留唯一索引；农历日两个唯一索引均存在，月内日号无重复。

复现只读审计：

```bash
python3 Scripts/BuildChineseCalendarSeedStore/verify_relationship_store.py \
  Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/ChineseCalendar.sqlite
python3 Scripts/BuildChineseCalendarSeedStore/verify_relationship_store.py \
  Data/Processed/remote_full_seed_store/ChineseCalendar.sqlite \
  --compare-to /path/to/schema-1.2.0-full.sqlite
```

## 完整库查询性能

`verify_relationship_store.py` 在同一台机器上，以分布在完整时间范围内的 999 个月和 807 个年分别查询新旧 store，每个样本逐项比较结果：

| SQL 查询 | 旧 median / P95 (ms) | 新 median / P95 (ms) |
| --- | ---: | ---: |
| 按月查日 | 0.0277 / 0.0513 | 0.0280 / 0.0526 |
| 按年查月 | 5.8260 / 6.1445 | 0.0190 / 0.0443 |

另外通过 Xcode `RunCodeSnippet` 在 `CalendarSelectionResolver.swift` 上下文中，打开完整 SQLite 并调用实际生产谓词：

| SwiftData 查询 | 样本数 | median / P95 (ms) |
| --- | ---: | ---: |
| `ChineseCalendarRelationshipPredicates.days(inMonth:)` | 999 | 0.6570 / 1.2341 |
| `ChineseCalendarRelationshipPredicates.months(inYear:)` | 807 | 0.5519 / 0.8590 |

这些是本机单次顺序抽样，包括 SwiftData 取出模型的成本；不代表冷启动、低端真机或多轮统计。SQL 与 SwiftData 的耗时不能直接混为一组。

实现中发现：直接使用 `day.chineseLunarMonth?.lunarMonthIndex == index`，当前 SwiftData 会生成 SQL `CASE`，完整库 median 约 60.8 ms、P95 62.4 ms。只检查等价手写 SQL 会漏掉该退化。

生产谓词集中于 `ChineseCalendarRelationshipPredicates`，先明确排除 nil，再解包关系；两个解包位置有局部 SwiftLint 豁免与原因说明，缺失数据仍由关系校验器拒绝。App 运行时的 `-com.apple.CoreData.SQLDebug 1` 证实最终 SQL 为：

```sql
FROM ZCHINESELUNARDAY t0
JOIN ZCHINESELUNARMONTH t1 ON t0.ZCHINESELUNARMONTH = t1.Z_PK
WHERE NOT (t0.ZCHINESELUNARMONTH IS NULL)
  AND (t0.ZCHINESELUNARMONTH IS NOT NULL AND t1.ZLUNARMONTHINDEX = ?)
ORDER BY t0.ZDAYNUMBERINMONTH, t0.Z_PK
```

该查询使用月稳定身份唯一索引和「月份关系 + 日号」唯一索引；App 日志中的 29 日查询耗时为 0.0004 秒。按年查月使用年唯一索引与 SwiftData 自动生成的年份关系索引。

## 安装和运行验证

- 新版 base 启动后，日历明确提示需要完整日期数据；朝代时间线 → 西汉 → 43 个年号列表正常。
- 独立空模拟器首次安装成功；将旧 base 及 manifest 放入 App Group 后重新启动，也成功替换为新版 base。
- 将校验过的旧 1.2.0 full 及其 manifest 放入测试 App Group，重新启动新版 App 后，manifest 变为 1.3.0 base，App 正常显示下载入口。
- 通过一次性启动环境变量 `CHINESE_CALENDAR_FULL_SEED_STORE_MANIFEST_URL` 指向本地清单，在 App 点击真实下载按钮。服务端记录 manifest 和 SQLite 的 HTTP 200；安装后 manifest 为 1.3.0 full，artifactVersion 与新制品一致。随后重启保留 full 并可显示日级数据。
- 本地服务使用 `http://localhost:8131`；本次模拟器访问 `127.0.0.1` 清单曾超时，换成 localhost 后通过。不修改生产网络配置。
- 完整库的今天定位、下个月及返回今天已运行验证；2025 年六月 → 闰六月的日期、标题和初一选中状态正确。
- 生产 resolver 在完整库中验证了月份 9 → 10 → 11（九月 → 后九月 → 次年十月）和 27773 → 27774 → 27775（六月 → 闰六月 → 七月），选中日反推月份、年份均一致。
- 独立模拟器完成后九月 → 次年十月、闰六月 → 七月和农历年 0 的十二月 → 年 1 的正月交互；标题、日期和初一选中状态随之更新。[闰月截图](issue-131/runtime-leap-month.jpg)、[后月截图](issue-131/runtime-post-month.jpg)、[跨年截图](issue-131/runtime-cross-year.jpg)、[年 1 截图](issue-131/runtime-ce-year.jpg)。
- 原配置模拟器被其他启动过程装回旧 schema，后续改用本次新建的独立模拟器完成检查，结束后恢复仓库配置。

## 远端发布

待发布制品：`full-seed-store-2026.10.03`，包含 `ChineseCalendar.sqlite` 与 `ChineseCalendarFullSeedStoreManifest.json`。
本地制品与安装流程已验证。远端发布及 `project.yml` 清单 URL 切换应一起完成，避免新 schema 继续下载旧 1.2.0 清单；发布前不能将公共下载路径视为完成。
