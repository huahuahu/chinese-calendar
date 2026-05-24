# SwiftData Seed Store

The app uses a prebuilt SwiftData store for the static Chinese calendar dataset. At runtime, the bundled seed store is copied into the shared App Group container, then both the app and future widget targets open that shared copy.

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
  ChineseCalendar.sqlite
  manifest.json
```

Installed shared store:

```text
<App Group Container>/ChineseCalendarStore/
  ChineseCalendar.sqlite
  manifest.json
```

`manifest.json` is compared at launch. If the bundled manifest changes, the shared store is replaced with the new seed store.

## Build The Seed Store

Generate the resource bundle from the JSONL import artifact:

```bash
swift run -c release --package-path Scripts/BuildChineseCalendarSeedStore ChineseCalendarSeedStoreBuilder \
  --input Data/Processed/swiftdata_import \
  --output Apps/Shared/Resources/ChineseCalendarSeedStore.bundle \
  --save-interval 5000
```

Xcode targets also run this command automatically before building if `ChineseCalendar.sqlite` is missing from the resource bundle. The builder checkpoints WAL content back into the main database, switches the seed store to DELETE journal mode, and removes SQLite sidecar files so the bundled seed store stays as a single SQLite file.

The source artifact is intentionally still kept under `Data/Processed/swiftdata_import`. The generated `.sqlite` file is an app resource, not source data.

## Notes

- SwiftData stores must live in a writable location, so the app does not open the bundle copy directly.
- The seed builder is an offline release/build step. Avoid doing this import on first app launch.
- Runtime containers open the copied seed store with `allowsSave: false`; the shared calendar data is read-only.
- The current builder keeps the store flat for large static data: relationships that can be resolved by stable keys, such as `lunarYearNumber` and `lunarMonthIndex`, are left as key-based lookups instead of eagerly building very large relationship arrays.
