---
name: publish-full-seed-store
description: Build, verify, and publish the Chinese calendar app's remote full SwiftData SQLite seed store when a full-store release or refresh is requested.
license: MIT
metadata:
  author: Tiger Guo
  version: "1.1"
---

# Publish a full seed store

Build the remote `full` store containing day-level calendar data. Preserve the bundled `base` store in `Apps/Shared/Resources/ChineseCalendarSeedStore.bundle`.

Use the current checkout and these canonical sources:

- [Builder workflow and verification](../../../Scripts/BuildChineseCalendarSeedStore/README.md).
- [Store identity, remote manifest, and installation contract](../../../Docs/data%20model/swiftdata-seed-store.md).
- [Identity implementation](../../../Scripts/BuildChineseCalendarSeedStore/seed_store_identity.mjs) and [remote manifest decoder](../../../Sources/ChineseCalendarPersistence/ChineseCalendarFullSeedStoreInstaller.swift).

Respect the requested stage. A build-only request ends with local artifacts; auditing or maintaining this skill does not authorize a build or release. A request to publish authorizes the new release within that scope. Do not push branches, create PRs, or overwrite an existing release's assets without the corresponding user authorization.

## Resolve inputs and release identity

- Resolve the active repository root with `git rev-parse --show-toplevel`; never switch to a hardcoded primary checkout.
- Use `Data/Processed/swiftdata_import` as input and `Data/Processed/remote_full_seed_store` as output unless the user specifies another dedicated artifact directory. Never point the full builder at the bundled base store, the input directory, or a directory containing unrelated work. The builder deletes its output directory by default; preserve any needed existing artifacts before running it.
- `datasetVersion` is the JSONL content SHA-256, not a date. Generate it together with `artifactVersion`, `schemaVersion`, `seedStoreFormatVersion`, `seedRecipeVersion`, and `seedStoreContentLevel` using `seed_store_identity.mjs`. Do not hand-set these fields or scrape an installer string literal: the schema comes from `ChineseCalendarModelSchema.versionIdentifier`.
- Use a supplied date/version label only in the release tag/title. Defaults are `full-seed-store-YYYY.MM.DD` and `Full seed store YYYY.MM.DD`, using the local date. Do not change the content identity to match a tag.
- Resolve the GitHub repository from the active checkout's remote and pass it explicitly with `--repo`. Use `main` as the release target unless the user specifies another target. Verify the selected ref exists and record which source revision built the artifact; a tag pointing at `main` does not prove that a dirty worktree matches it.
- Apply the complete proxy environment from `AGENTS.md` to each network command. Do not add it to local-only validation or builds. If package resolution needs network access, perform it with the required proxy first.

## Build and validate locally

Run from the active repository root, after resolving the output directory above. The identity file must be outside the output directory because the builder resets that directory.

```bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
input_dir="$repo_root/Data/Processed/swiftdata_import"
output_dir="$repo_root/Data/Processed/remote_full_seed_store"
identity_file="$(mktemp)"
trap 'rm -f "$identity_file"' EXIT

node Scripts/DataSchemas/validate_swiftdata_import.mjs --input "$input_dir"
node Scripts/BuildChineseCalendarSeedStore/seed_store_identity.mjs \
  --input "$input_dir" --content-level full --output "$identity_file"
swift run -c release --package-path Scripts/BuildChineseCalendarSeedStore ChineseCalendarSeedStoreBuilder \
  --input "$input_dir" --output "$output_dir" --content-level full \
  --identity-file "$identity_file" --save-interval 5000
node Scripts/BuildChineseCalendarSeedStore/seed_store_identity.mjs \
  --input "$input_dir" --content-level full --check-manifest "$output_dir/manifest.json"
python3 Scripts/BuildChineseCalendarSeedStore/verify_relationship_store.py \
  "$output_dir/ChineseCalendar.sqlite"
```

The post-build identity check rejects inputs changed during generation. If it fails, do not publish the artifact. Resolve the input change and rebuild. Require the relationship audit to pass, `PRAGMA journal_mode` to report `delete`, and day/month/year row counts to match the current import/runtime manifests; do not copy historical row counts as release requirements.

Before publishing, require both `ChineseCalendar.sqlite` and runtime `manifest.json`, with no `ChineseCalendar.sqlite-*` sidecars. Never repair a failed build merely by deleting WAL/SHM files; let the builder checkpoint and finalize a fresh artifact.

## Prepare the remote manifest

Set `download_url` to the selected repository/tag's final HTTPS download URL for `ChineseCalendar.sqlite`. Generate `ChineseCalendarFullSeedStoreManifest.json` from the validated runtime manifest, preserving its identity rather than maintaining another version source. The following command streams the SQLite checksum and refuses leftover sidecars:

```bash
python3 - "$output_dir" "$download_url" <<'PY'
import hashlib
import json
from pathlib import Path
import sqlite3
import sys

output = Path(sys.argv[1])
store = output / "ChineseCalendar.sqlite"
runtime = json.loads((output / "manifest.json").read_text())
keys = ("datasetVersion", "artifactVersion", "schemaVersion", "seedStoreContentLevel",
        "seedStoreFormatVersion", "seedRecipeVersion")
manifest = {key: runtime[key] for key in keys}
assert manifest["seedStoreContentLevel"] == "full"
assert not list(output.glob("ChineseCalendar.sqlite-*")), "SQLite sidecars remain"
assert store.stat().st_size > 0
with sqlite3.connect(store.resolve().as_uri() + "?mode=ro", uri=True) as connection:
    assert connection.execute("PRAGMA journal_mode").fetchone()[0] == "delete"
    assert connection.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
with store.open("rb") as source:
    digest = hashlib.file_digest(source, "sha256").hexdigest()
manifest.update(storeFileName=store.name, byteCount=store.stat().st_size,
                sha256=digest, downloadURL=sys.argv[2])
assert manifest["downloadURL"].startswith("https://")
(output / "ChineseCalendarFullSeedStoreManifest.json").write_text(
    json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
PY
```

Keep the runtime manifest and identity evidence with the local build results. Upload only the finalized SQLite and remote manifest. The extra `seedRecipeVersion` preserves generation provenance; the current app decoder ignores unknown fields. Do not commit generated full-store artifacts.

## Publish and read back

1. Immediately before the external mutation, ensure the user requested publication and inspect `gh release view <tag> --repo <owner/repository>`. An authentication, network, or permission error is not proof that a release is absent. If the release already exists, inspect its assets and stop before replacement; use a new user-approved tag or explicit overwrite authorization.
2. Create the new release with the two exact files, explicit `--repo`, `--target`, and `--title`. Write multiline release notes to a temporary file and pass `--notes-file`. Include source revision, content/artifact/schema identities, byte count, and SHA-256.
3. If creation/upload times out, inspect the release and assets before retrying. Do not blindly rerun creation, delete assets, or use `--clobber`. If this attempt left a partial release, upload only confirmed missing assets within the existing publication authorization; stop on conflicting files or uncertain state.
4. Read back release metadata and both assets. Download the manifest and SQLite into a separate temporary directory via their final URLs. Require the manifest to equal the prepared manifest, asset size to equal `byteCount`, and the downloaded SQLite's byte count and SHA-256 to equal the manifest and local artifact. A release listing or successful upload alone is not end-to-end verification. Report a blocked/incomplete download check separately.
5. Once remote verification passes, update `ChineseCalendarFullSeedStoreManifestURL` entries in `project.yml` when the request includes switching the app to the new release. Update only the intended targets. Use the normal project generator when local testing needs generated Info.plist/project files; do not hand-edit generated files as the source of truth.

## Validation and delivery

- For skill-only maintenance, run the skill creator's `quick_validate.py` and the existing isolated identity tests: `node --test Scripts/BuildChineseCalendarSeedStore/Tests/seed_store_identity.test.mjs`. Exercise any changed manifest-generation example against a small temporary SQLite fixture; do not build or publish a full dataset for a documentation check.
- For an actual release, report input validation, identity validation, relationship/SQLite checks, and remote read-back independently. If app source/configuration changes require a build or installation test, follow [the Xcode workflow](../../../Docs/agent-workflows.md#xcode-project-context) and shared tool context. Do not use host `swift test --package-path Sources` as iOS app/UI validation.
- Report the tag/release URL, source revision, `datasetVersion` and `artifactVersion`, schema/format versions, SQLite byte count and SHA-256, remote manifest URL, whether app configuration changed, and any unverified stages. Keep build/upload/remote-integrity/app-installation evidence distinct.
