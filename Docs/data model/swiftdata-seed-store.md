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
  manifest.json                 # compact runtime manifest, includes seedStoreContentLevel: base
```

Installed shared store:

```text
<App Group Container>/ChineseCalendarStore/
  ChineseCalendar.sqlite
  manifest.json
```

At launch, the bundled and installed manifests are compared by `artifactVersion`. Provenance-only fields such as `generatedAt` do not trigger a reinstall. If the App Group copy is missing, the bundled base store is installed. If the installed copy is already a `full` store, the bundled base store never replaces it.

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
  "schemaVersion": "1.2.0",
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

Ordinary iOS and macOS Xcode builds run `validate_seed_store.sh`. The phase recalculates the base identity, fails with a `make seed-store` instruction when the committed artifact is stale, and writes only a DerivedData stamp when validation succeeds. It never rewrites the tracked SQLite or manifest.

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

Full identities additionally cover every `calendar_days/**/*.jsonl` file. Publish the full `ChineseCalendar.sqlite` plus a remote manifest that includes its `artifactVersion`, byte count, and SQLite SHA-256 digest. The app downloads the SQLite file into a staging directory, verifies it, opens it with SwiftData once, then atomically installs it into the App Group store directory.

The source artifact is intentionally still kept under `Data/Processed/swiftdata_import`. The generated `.sqlite` file is an app resource, not source data.

## Notes

- SwiftData stores must live in a writable location, so the app does not open the bundle copy directly.
- The seed builder is an offline release/build step. Avoid doing this import on first app launch.
- Runtime containers open the copied seed store with `allowsSave: false`; the shared calendar data is read-only.
- The full store is installed only after validation. The seed builder purges SwiftData/Core Data transaction-history rows before publishing stores; no app-defined history tracking metadata is kept in SQLite.
- The current builder keeps the store flat for large static data: relationships that can be resolved by stable keys, such as `lunarYearNumber` and `lunarMonthIndex`, are left as key-based lookups instead of eagerly building very large relationship arrays.
