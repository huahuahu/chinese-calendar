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

Any widget extension that needs calendar data should use the same App Group entitlement and open its `ModelContainer` through `ChineseCalendarModelContainerFactory.sharedContainer`.

## Runtime Layout

Bundled resource:

```text
Apps/Shared/Resources/ChineseCalendarSeedStore.bundle/
  ChineseCalendar.sqlite        # base store, tracked in git
  manifest.json                 # includes seedStoreContentLevel: base
```

Installed shared store:

```text
<App Group Container>/ChineseCalendarStore/
  ChineseCalendar.sqlite
  manifest.json
```

`manifest.json` is compared at launch. If the App Group copy is missing, the bundled base store is installed. If the installed copy is already a `full` store, the bundled base store never replaces it.

Remote full-store manifest:

```json
{
  "datasetVersion": "2026.05.30",
  "schemaVersion": "1.1.0",
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

Generate the resource bundle from the JSONL import artifact:

```bash
swift run -c release --package-path Scripts/BuildChineseCalendarSeedStore ChineseCalendarSeedStoreBuilder \
  --input Data/Processed/swiftdata_import \
  --output Apps/Shared/Resources/ChineseCalendarSeedStore.bundle \
  --content-level base \
  --save-interval 5000
```

Xcode targets also run this command automatically before building if `ChineseCalendar.sqlite` is missing from the resource bundle, or if the bundled store is not the expected base-store format. The builder checkpoints WAL content back into the main database, switches the seed store to DELETE journal mode, and removes SQLite sidecar files so the bundled seed store stays as a single SQLite file.

To build a remote full store, use a separate output directory:

```bash
swift run -c release --package-path Scripts/BuildChineseCalendarSeedStore ChineseCalendarSeedStoreBuilder \
  --input Data/Processed/swiftdata_import \
  --output Data/Processed/remote_full_seed_store \
  --content-level full \
  --save-interval 5000
```

Publish the full `ChineseCalendar.sqlite` plus a remote manifest that includes its byte count and SHA-256 digest. The app downloads the SQLite file into a staging directory, verifies it, opens it with SwiftData once, then atomically installs it into the App Group store directory.

The source artifact is intentionally still kept under `Data/Processed/swiftdata_import`. The generated `.sqlite` file is an app resource, not source data.

## Notes

- SwiftData stores must live in a writable location, so the app does not open the bundle copy directly.
- The seed builder is an offline release/build step. Avoid doing this import on first app launch.
- Runtime containers open the copied seed store with `allowsSave: false`; the shared calendar data is read-only.
- The full store is installed only after validation. The seed builder purges SwiftData/Core Data transaction-history rows before publishing stores; no app-defined history tracking metadata is kept in SQLite.
- The current builder keeps the store flat for large static data: relationships that can be resolved by stable keys, such as `lunarYearNumber` and `lunarMonthIndex`, are left as key-based lookups instead of eagerly building very large relationship arrays.
