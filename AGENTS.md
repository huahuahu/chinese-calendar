# AGENTS.md

This repository hosts a Swift project for browsing the traditional Chinese calendar on iOS and macOS.

## Goals

- Build a shared Swift codebase for iOS and macOS.
- Import Chinese calendar source data from [ytliu0/ChineseCalendar](https://github.com/ytliu0/ChineseCalendar).
- Present historical calendar data in a clean browsing experience.

## Current Structure

- `Sources/Package.swift`: Shared Swift Package definition.
- `Sources/ChineseCalendarCore`: Domain models and calendar logic.
- `Sources/ChineseCalendarData`: Data loading and repository abstractions.
- `Sources/ChineseCalendarUI`: Shared SwiftUI views.
- `Apps/iOSApp`: iOS app entry point and app-specific code.
- `Apps/macOSApp`: macOS app entry point and app-specific code.
- `Data/Raw`: Downloaded upstream source data.
- `Data/Processed`: Normalized app-ready data artifacts.
- `Scripts/ImportChineseCalendar`: Import and transformation scripts.

## Working Rules

- Prefer keeping business logic in shared package targets instead of app targets.
- Treat `ChineseCalendarCore` as the source of truth for domain models.
- Keep platform-specific UI behavior in `Apps/iOSApp` and `Apps/macOSApp` only when sharing is not practical.
- Store fetched upstream files in `Data/Raw` and generated artifacts in `Data/Processed`.
- Make small, reviewable commits.
- Do not use `git commit --amend` when changing or committing work; create a new commit instead.

## Common Commands

- `swift build --package-path Sources`
- `swift test --package-path Sources`
- `git status --short`

## Near-Term Priorities

1. Add importer scripts for the upstream Chinese calendar dataset.
2. Define stable app-side data models and serialization format.
3. Build a calendar browsing UI backed by real imported data.
4. Create an Xcode project or workspace that wraps the shared package targets.

## Notes for GitHub Copilot

- Before adding new modules, check whether the code belongs in an existing shared package target.
- Prefer incremental scaffolding over large speculative implementations.
- When touching data import logic, document the upstream source and output format.

## Installed Agent Resources

- Project-local skill: `./.agents/skills/grill-with-docs`
- Project-local skill: `./.agents/skills/swiftui-pro`
- Project-local skill: `./.agents/skills/swift-concurrency-pro`
- Project-local skill: `./.agents/skills/swiftdata-pro`
- Project-local skill: `./.agents/skills/publish-full-seed-store`
- Project-local skill: `./.agents/skills/worktree-cleanup`
- Project-local skill: `./.agents/skills/cleaning-merged-pr-worktrees`
- Project-local skill: `./.agents/skills/screen-flow-prototype`

## Apple Documentation

- Prefer the sosumi MCP for Apple Developer Documentation, Human Interface Guidelines, and Apple Developer video transcripts before using web search or direct fetch tools.
- Use non-sosumi sources only when the needed material is not available through sosumi.

## XcodeBuildMCP

- XcodeBuildMCP is installed as a CLI and exposed through MCP. Prefer XcodeBuildMCP tools over direct `xcrun simctl` calls whenever XcodeBuildMCP exposes the needed operation.
- Use `xcrun simctl` only for simulator lifecycle operations not exposed by XcodeBuildMCP, such as creating or deleting branch-scoped simulators in the worktree skills.
- Project defaults live in `.xcodebuildmcp/config.yaml`.
- At the start of each new agent session, before the first xcodebuildmcp build/run/test call, show active defaults with `session_show_defaults`.
- If active defaults are missing or differ from `.xcodebuildmcp/config.yaml`, read `sessionDefaults` from that file and apply them with `session_set_defaults` before building, running, or testing.
- Resolve any relative `projectPath` in `sessionDefaults` from the repository root before calling `session_set_defaults` (for example, `ChineseCalendar.xcodeproj` becomes `<repo-root>/ChineseCalendar.xcodeproj`).

## Simulator in Codex Browser

- When the user asks to view or operate the running iOS app in the Codex in-app browser, use the `ios-simulator-browser` skill together with the in-app browser skill.
- Use the simulator selected by XcodeBuildMCP. Read `sessionDefaults.simulatorId` from `.xcodebuildmcp/config.yaml` when session-default tools are unavailable; do not choose a different booted simulator by name.
- `serve-sim` must run without inherited proxy variables. A proxy-launched process can capture the framebuffer while the browser remains at `Connecting...` or reports `control socket connect timeout`. If the package is not cached yet, fetch/cache it in a separate command using the repository's required full proxy environment, then start the actual mirror offline with all proxy variables removed.
- Start a simulator-scoped, long-running mirror and keep its terminal alive while the browser is using it. Never use an unscoped `serve-sim --kill`:

  ```bash
  SIM="<sessionDefaults.simulatorId>"
  cleanup_serve_sim() {
    env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      -u http_proxy -u https_proxy -u all_proxy \
      -u NO_PROXY -u no_proxy \
      npx --offline --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
  }
  trap cleanup_serve_sim EXIT INT TERM HUP
  cleanup_serve_sim
  env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
    -u http_proxy -u https_proxy -u all_proxy \
    -u NO_PROXY -u no_proxy \
    npx --offline --yes serve-sim@latest "$SIM"
  ```

- Open the exact local URL printed by `serve-sim` (normally `http://localhost:3200`) in the Codex in-app browser. Do not report success until the status is `live`, a real app frame is visible, and one simulator interaction such as switching tabs has visibly changed the app.
- If the in-app browser reports that its webview did not attach, keep the existing browser binding, create a fresh tab, and retry the local URL. Navigation can replace the browser tab ID; if a later action says the tab is missing, list tabs and reacquire the current `Simulator - <device name>` tab instead of restarting the simulator mirror.
- If `serve-sim` shows `Connecting...`, inspect its terminal. Framebuffer/encoder-ready messages prove capture started but not that the control socket is usable. Restart the mirror with the proxy variables removed as above; after it becomes `live`, browser coordinate clicks can operate the streamed simulator UI.

## Swift Agent Guidance

The project keeps its own repository-specific rules above, but also adopts the spirit of Paul Hudson's Swift agent guidance:

- Prefer modern Swift and SwiftUI API over legacy alternatives.
- Favor Swift concurrency and safe state management patterns.
- Avoid third-party dependencies unless there is a clear project need.
- Keep SwiftUI code accessible, testable, and structurally simple.
- When current Apple API behavior matters, use fetched Apple documentation as the reference for implementation and reviews.

When a task is primarily about SwiftUI review or generation, prefer using the local `swiftui-pro` skill.
When a task is primarily about async/await, actor isolation, cancellation, or task structure, prefer `swift-concurrency-pro`.
When a task is primarily about SwiftData models, predicates, indexing, or CloudKit integration, prefer `swiftdata-pro`.
When publishing a new remote full SwiftData seed store SQLite release, prefer `publish-full-seed-store`.
When cleaning up branch worktrees, prefer `worktree-cleanup`.
When cleaning up a local worktree for a PR that was already merged, closed, or whose remote branch was deleted, prefer `cleaning-merged-pr-worktrees`.
