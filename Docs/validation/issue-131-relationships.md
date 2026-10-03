# Issue #131：SwiftData 关系与索引验证

验证日期：2026-10-03。基线 `6d354fa9`，最终 schema 从 1.2.0 更新为 **1.4.0**。
初轮实现和运行验证使用过临时的 1.3.0；随后确认已发布的
[`full-seed-store-2026.08.30`](https://github.com/huahuahu/chinese-calendar/releases/tag/full-seed-store-2026.08.30)
清单已经使用 1.3.0，因此本次关系重构改用 1.4.0，避免把历史数据包误判为兼容。
下方保留初轮验证的版本、制品身份和运行证据；最终 1.4.0 的重建与兼容验证见文末补充。
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
可随仓库复核的初轮 [SQLite 审计结果](issue-131/full-store-audit.json)、[SwiftData 查询结果](issue-131/full-swiftdata-results.txt) 一并保存。[查询片段](issue-131/full-swiftdata-snippet.swift) 已更新为最终 1.4.0 的实现；在上述源码上下文中运行，并把 store 路径改成自己的完整库路径。

## 初轮数据制品

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
full 输出目录为被 Git 忽略的 `Data/Processed/remote_full_seed_store`，当前已替换为文末的 1.4.0 制品；不提交大型远端制品。

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

## 初轮完整库查询性能

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

初轮谓词集中于 `ChineseCalendarRelationshipPredicates`，先明确排除 nil，再解包关系。该实现随后被 CI 证实不支持 iOS 26.5，已移除；下面 SQL 仅作为初轮 iOS 27 的诊断记录保留。最终实现与性能见文末。

```sql
FROM ZCHINESELUNARDAY t0
JOIN ZCHINESELUNARMONTH t1 ON t0.ZCHINESELUNARMONTH = t1.Z_PK
WHERE NOT (t0.ZCHINESELUNARMONTH IS NULL)
  AND (t0.ZCHINESELUNARMONTH IS NOT NULL AND t1.ZLUNARMONTHINDEX = ?)
ORDER BY t0.ZDAYNUMBERINMONTH, t0.Z_PK
```

该查询使用月稳定身份唯一索引和「月份关系 + 日号」唯一索引；App 日志中的 29 日查询耗时为 0.0004 秒。按年查月使用年唯一索引与 SwiftData 自动生成的年份关系索引。

## 初轮安装和运行验证

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

待发布制品：schema **1.4.0** 的 `full-seed-store-2026.10.03`，包含 `ChineseCalendar.sqlite` 与 `ChineseCalendarFullSeedStoreManifest.json`。
远端发布及 `project.yml` 清单 URL 切换应一起完成，避免新 schema 继续下载旧 1.2.0 清单。已发布的 1.3.0 清单也不兼容本次关系重构；发布前不能将公共下载路径视为完成。

## 最终 schema 1.4.0 验证

- 模型字符串版本、`Schema.Version(1, 4, 0)`、base/full runtime manifest，以及两份 SQLite 的 `NSStoreModelVersionIdentifiers` 均为 1.4.0。
- base/full 重新生成并通过稳定内容身份校验、SQLite integrity、必需关系、删除字段与唯一索引审计；无 WAL/SHM sidecar。full 仍包含 884,256 条农历日。
- 新增 1.3.0 兼容用例：已安装旧 base/full 会替换为当前 base，旧远端清单在下载前被拒绝；继续覆盖 1.2.0。
- 原 PR 的 iOS 26.5 CI 暴露 `PredicateExpressions.ForcedUnwrap` 不受支持。最终移除该谓词实现，使用 `ChineseCalendarRelationshipQueries` 读取有界的 `month.days` / `year.months` 关系集合并按业务顺序排序。导航先按模型自身稳定身份定位父对象，再读取关系；日期网格与 Preview 使用实际已入库的月份对象。
- iOS 26.5 的 Persistence/UI 测试结果为 **113 项通过、0 失败**（摘要 `D90933CA-8FC4-45B2-A6FA-AE114DFC1351.txt`）；恢复配置的 iOS 27.0 模拟器后，工具返回 **91 项通过、0 失败**（摘要 `98E59183-FFAC-4FCE-8759-73CF45D5C098.txt`）。两次均请求同一组 87 个测试标识，记录工具实际展开并返回的结果数。
- 「30 天与选中日」和「29 天的小月」Preview 均成功渲染并显示日期。Xcode Preview 实际选用 iPhone Duo / iOS 27.1；未重新渲染其余全部 Preview，也未重复完整下载 UI 流程。
- 3 项 seed identity Node 测试、SwiftFormat、严格 SwiftLint、`git diff --check` 通过。

最终制品：[身份与校验和](issue-131/schema-1.4-artifacts.json)、[full 审计](issue-131/full-store-audit-1.4.json)。

| 制品 | 字节数 | artifactVersion |
| --- | ---: | --- |
| base 1.4.0 | 2,658,304 | `43ae5b55e0290f25451885dca5458022bedf647e7d868ad35d546f36a6d54637` |
| full 1.4.0 | 207,093,760 | `465fb388943cc8aeba67ee7e6b83807c8dc01ecf3606636eae2bfbbeb0f924a1` |

最终 full SHA-256：`0e0b3688f2f410d5343a5a9f2ee5f1b60b7f74f179d680dd97805b3e40895989`。

使用最终代码在完整库上重新运行 [查询片段](issue-131/full-swiftdata-snippet.swift)，[结果](issue-131/full-swiftdata-results-1.4.txt) 包括父对象查找、关系加载和排序，均为本机单次顺序抽样：

| SwiftData 关系加载 | 样本数 | median / P95 (ms) |
| --- | ---: | ---: |
| 按月读取日期 | 999 | 3.3990 / 4.1060 |
| 按年读取月份 | 807 | 2.0790 / 2.4580 |

这比初轮 iOS 27 专用的直接过滤慢，但不再使用不受支持的解包谓词，也未出现可选链全表扫描的约 60 ms 延迟。完整库关系校验及后月、闰月、跨年导航结果均通过；最终公开下载仍待发布后验证。
