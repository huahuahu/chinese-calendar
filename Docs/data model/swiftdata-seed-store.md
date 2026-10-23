# SwiftData Seed Store

The app uses two prebuilt SwiftData stores for the static Chinese calendar dataset:

- a bundled `base` seed store, tracked in git and shipped with the app;
- an optional remote `full` seed store, downloaded after launch and installed into the same App Group location.

The base store contains the shared schema, lunar years, lunar months, and dynasty/orthodox-period metadata. It intentionally does not contain day-level rows. The full store uses the same schema and includes all day-level data.

## App Group

The shared container identifier is:

```text
group.com.tiger.suzhou.ChineseCalendar
```

当前 App 的读取统一通过 `ChineseCalendarModelContainerFactory` 打开容器，以登记其存储生命周期。当前没有 Widget 等独立进程读库；若以后增加，除共享 App Group entitlement 外，还必须为存储回收补充跨进程 lease。当前进程内的弱容器登记不能保护其他进程正在读取的文件。

## Runtime Layout

Bundled resource:

```text
Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/
  ChineseCalendar.sqlite        # base store, tracked in git
  manifest.json                 # compact runtime manifest, includes seedStoreContentLevel: base
```

Installed shared store:

```text
<App Group Container>/ChineseCalendarStore/
  current-generation             # 原子写入的当前目录 UUID
  generations/
    <UUID>/
      ChineseCalendar.sqlite
      manifest.json
```

没有 `current-generation` 时兼容旧版根目录的 `ChineseCalendar.sqlite` 和 `manifest.json`。下一次替换写入独立 generation，不修改或删除仍在使用的旧库。每次换库的目录身份独立于 `artifactVersion`；同一份基础库再次安装也会创建新容器和目录。

At launch, the bundled and installed manifests are compared by `artifactVersion`. Provenance-only fields such as `generatedAt` do not trigger a reinstall. If the App Group copy is missing, the bundled base store is installed. An installed `full` store is handled by schema compatibility instead of `artifactVersion` alone.

A downloaded `full` store is preserved while its `schemaVersion` matches the app, even if the bundled base store has a different `artifactVersion`. An incompatible full store is replaced with the bundled base store so the read-only database never requires an in-place migration.

The stable identity fields are:

- `datasetVersion`: SHA-256 of the semantic JSONL inputs in stable filename order;
- `schemaVersion`: the explicit `ChineseCalendarModelSchema` version;
- `seedStoreFormatVersion`: the SQLite publishing format version;
- `seedRecipeVersion`: explicitly incremented when generation rules change semantically;
- `artifactVersion`: SHA-256 of the four values above plus `seedStoreContentLevel`.

Timestamps and source-audit provenance are retained for diagnosis, but are excluded from both hashes.

Remote full-store manifest:

```json
{
  "datasetVersion": "<sha256>",
  "artifactVersion": "<sha256>",
  "schemaVersion": "1.4.0",
  "seedStoreContentLevel": "full",
  "seedStoreFormatVersion": 4,
  "storeFileName": "ChineseCalendar.sqlite",
  "byteCount": 123456789,
  "sha256": "...",
  "downloadURL": "https://example.com/ChineseCalendar.sqlite"
}
```

Configure the remote manifest URL with either the `ChineseCalendarFullSeedStoreManifestURL` Info.plist key or the `CHINESE_CALENDAR_FULL_SEED_STORE_MANIFEST_URL` environment variable.

## Build The Seed Store

Generate or update the version-controlled base resource bundle from the JSONL import artifact:

```bash
make seed-store
```

This is the only normal entry point that writes `Apps/Shared/Resources/ChineseCalendarSeedStore.bundle`. It calculates the current identity first and skips generation when `artifactVersion` already matches. The builder checkpoints WAL content back into the main database, switches the seed store to DELETE journal mode, and removes SQLite sidecar files so the bundled seed store stays as a single SQLite file.

Ordinary iOS Xcode builds run `validate_seed_store.sh`. The phase recalculates the base identity, fails with a `make seed-store` instruction when the committed artifact is stale, and writes only a DerivedData stamp when validation succeeds. It never rewrites the tracked SQLite or manifest.

The processed import directory under `Data/Processed/swiftdata_import` keeps JSONL import data, a compact manifest, and a separate `dynasty_source_audit.json` for dynasty import audit details. The resource-bundle manifest is intentionally slim: it keeps only runtime install/version fields, coverage counts, and compact provenance. Dynasty and orthodox-period records are read from the SwiftData SQLite tables, not duplicated in manifests.

To build a remote full store, calculate a full identity first and use a separate output directory:

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

Full identities additionally cover every `calendar_days/**/*.jsonl` file. Publish the full `ChineseCalendar.sqlite` plus a remote manifest that includes its `artifactVersion`, byte count, and SQLite SHA-256 digest. App 先下载并校验文件，再将 SQLite 和 manifest 放入独立 generation，在最终位置打开容器并校验必要关系，最后原子发布 `current-generation`。已打开的容器随安装结果交给 UI，避免发布后重新打开的间隙。

The source artifact is intentionally still kept under `Data/Processed/swiftdata_import`. The generated `.sqlite` file is an app resource, not source data.

## 运行时替换与回收

- 打开当前库时，从指针解析到容器登记之间持有短期读 lease；正在准备的候选目录也参与登记。发布与回收通过同一把锁协调。
- `clearDownloadedSeedStore` 返回已打开的基础 `ModelContainer`。新库准备或发布失败时保留原指针和旧容器；发布后的下载缓存清理失败单独记录，不把已经完成的换库报告为失败。
- 清理下载数据先取消并等待实际安装任务退出，再发布基础库，防止被取消下载的后台任务随后重新发布完整库。
- UI 从已打开容器的实际 URL 读取同一代 manifest。根页和递归模态内容按容器实例重建并保活退出中的旧容器；导航宿主保留，以完成关闭回调和结果提示。相同 artifact 的新容器也会失效旧年份选择会话。
- 只回收非当前、非准备中、没有读 lease 且没有活跃登记容器的目录。页面释放容器、后续切换和冷启动会再次尝试回收。清理成功后立即使用基础数据；若旧页面或 Context 仍持有旧容器，磁盘空间可稍后释放，不用固定延时推测安全删除时机。

修复背景、回归和实际交互证据见 [Issue #164 结果](../Tasks/issue-164-typed-alert-actions/001-result.md)。

## Notes

- SwiftData stores must live in a writable location, so the app does not open the bundle copy directly.
- The seed builder is an offline release/build step. Avoid doing this import on first app launch.
- Runtime containers open the copied seed store with `allowsSave: false`; the shared calendar data is read-only.
- The full store is installed only after validation. The seed builder purges SwiftData/Core Data transaction-history rows before publishing stores; no app-defined history tracking metadata is kept in SQLite.
- The builder resolves JSONL association keys to actual SwiftData relationships: month → year, day → month, boundary → tradition/date, and period → tradition/dynasty/boundaries. It caches persistent month identifiers and resets day-import contexts in batches, so it does not need to retain every day in one large array. Runtime models do not duplicate those association keys.
- Schema 1.4.0 removes eight duplicated association fields and eight redundant standalone `id` indexes. Day identity stays unique, and a compound unique constraint covers the month relationship plus day number.
- Existing base and full stores with a different or missing schema version are replaced with the bundled base before opening. Users can then download the compatible full store. Compatible installed full stores are preserved. There is no in-place migration of the read-only dataset. Remote manifests with old schema versions fail before downloading; downloaded stores must open and pass required-relationship validation before installation.

## Relationship query verification

Month/day and year/month lookups first fetch the parent by its stable identity, then use `ChineseCalendarRelationshipQueries` to read and sort the bounded `month.days` or `year.months` relationship collection. This supports iOS 26.5 and avoids both unsupported unwrapping predicates and the unindexed SQL `CASE` generated by optional-chain filters. See the [Issue #131 validation record](../validation/issue-131-relationships.md) for build, uniqueness, installation compatibility, full-store performance, and Simulator evidence.
