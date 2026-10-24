# Scripts

Utility scripts for fetching, normalizing, generating app-ready data, and validating local/CI builds.

## Worktree Simulator Allocation

`ensure_worktree_simulator.py` requires Python 3.9+, the pinned PyYAML dependency in `Scripts/requirements.txt`, Git, and the selected Xcode's `simctl`. For a local environment, create and activate a virtual environment, then install the dependency through the configured local proxy:

```bash
python3 -m venv .output/python-venv
source .output/python-venv/bin/activate
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 python3 -m pip install -r Scripts/requirements.txt
```

Use that environment for local setup/build/test scripts. If your selected Python already has the pinned dependency, no environment changes are needed. CI selects Python 3.12 with `actions/setup-python` and installs the same requirements before running tests. The tests fail when required dependencies are missing instead of silently skipping validation.

Run the allocator before choosing a Simulator in either MCP:

```bash
python3 Scripts/ensure_worktree_simulator.py --dry-run
python3 Scripts/ensure_worktree_simulator.py
python3 Scripts/ensure_worktree_simulator.py --worktree "/path/to/another worktree"
```

The source of truth is the selected worktree's `.xcodebuildmcp/config.yaml`. If another worktree registered by `git worktree list` references the same UUID, the script creates an empty device with the same device type and runtime and updates `sessionDefaults.simulatorId` and `simulatorName`. Other settings and other worktrees' files are preserved. It does not clone app data, start, stop, or erase existing devices. Without a conflict, repeated runs reuse the device. Logs go to stderr; successful allocation prints only the chosen UUID to stdout.

A missing local configuration is initialized from `.xcodebuildmcp/config.example.yaml`. The template's `simulatorName` can identify an existing device, or an installed device type; in the latter case the script creates a device using the newest available compatible iOS runtime. Ambiguous names and unavailable configured UUIDs fail with a diagnostic. Fix the local configuration explicitly instead of silently changing runtime. To recreate a deleted device, remove its obsolete UUID and set `simulatorName` to the intended device type. Snapshot tests still require their documented exact runtime and device type.

The real configuration is ignored by Git. Change the template when sharing project defaults; machine-specific UUIDs belong only in the local file. Existing worktrees on older commits can still track their own configuration until they adopt this change. This migration preserves the current checkout's local file using `git rm --cached`; Git history is not rewritten.

The allocation transaction uses a file lock in the Git common directory and atomic configuration replacement. It serializes concurrent allocation calls from this repository, including multiple calls for the same worktree. It detects **configuration references**, not live device usage: separate clones/repositories, manual Xcode choices, and tasks that bypass this script are outside its scope. This lock ends when allocation finishes; it is not a lock around the later build/test/UI session.

`setup_worktree.sh`, local `ios_simulator.sh` consumers (test/build), `generate_build_index.sh`, and local snapshot tests run the allocator automatically. CI keeps its runner-specific selection. An explicit `SNAPSHOT_SIMULATOR_ID` continues to override the local snapshot allocation. After any allocation change, reconcile the MCP defaults and any browser mirror with the resulting configuration.

Run the isolated integration tests with `python3 Scripts/tests/test_ensure_worktree_simulator.py`. They use temporary Git worktrees and a fake `xcrun`, without touching real devices. `Scripts/test.sh` also runs them.

## Navigation API Validation

`validate_navigation_public_api.py` checks the public NavigationCore API against existing Simulator build products. It uses ordinary `import NavigationCore`: supported calls must compile, and each negative sample must fail with the expected access or missing-symbol diagnostic. Build the Debug Simulator modules first, then run:

```bash
python3 Scripts/validate_navigation_public_api.py \
  <Build/Products/Debug-iphonesimulator> \
  <iPhoneSimulator.sdk> \
  arm64-apple-ios26.0-simulator
```

Use the SDK and target that match the build. Reports and generated samples go to `.output/navigation-public-api/`; the script does not rebuild any target. Fixtures live in `Scripts/NavigationCoreAPI/`.

The former `validate_navigation_identity_types.py` was retired when Issue #165 made Core presentation identities internal and removed App session identities. Issue #166 evidence retains the historical verifier name; internal identity behavior remains covered by `NavigationIdentityTests.swift`.
