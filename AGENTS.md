# AGENTS.md

Chinese-date is an iOS app for browsing traditional Chinese calendar data, including source data from [ytliu0/ChineseCalendar](https://github.com/ytliu0/ChineseCalendar).

## Architecture and Scope

- Keep business logic in the shared package defined by `Sources/Package.swift`; use `Apps/iOSApp` for platform entry points and app-specific behavior.
- Treat `Sources/ChineseCalendarCore` as the source of truth for calendar domain logic and value types. SwiftData models and store lifecycle belong in `Sources/ChineseCalendarPersistence`; data loading and repository abstractions belong in `Sources/ChineseCalendarData`.
- Shared SwiftUI views belong in `Sources/ChineseCalendarUI`; shared navigation infrastructure belongs in `Sources/NavigationCore`.
- Store upstream inputs in `Data/Raw` and generated data artifacts in `Data/Processed`. When changing `Scripts/ImportChineseCalendar`, document the upstream source and output format.
- `project.yml` is the XcodeGen source; `ChineseCalendar.xcodeproj` is generated. Make lasting project configuration changes in the source configuration.

## Working Rules

- Before adding a module or dependency, check whether the work belongs in an existing shared target. Avoid third-party dependencies without a clear project need.
- Keep changes focused and incremental, and make small, reviewable commits.
- Do not use `git commit --amend` when changing or committing work; create a new commit instead.

## Shared Implementation and Review Rules

- Apply the same project rules when implementing and reviewing changes. Read `CONTEXT.md` and relevant `Docs/` documents for domain terminology, behavior, and accepted decisions; cite those sources instead of maintaining a second coding standard inside a review skill.
- Keep project coding conventions under `Docs/Conventions/`, indexed in [Docs/README.md](Docs/README.md). This file defines when to read them; module READMEs and skills link to the canonical topic instead of duplicating its rules.
- Before implementing or reviewing code, read [the common conventions](Docs/Conventions/Common.md).
- Before creating, modifying, or reviewing SwiftUI views, read [the SwiftUI conventions](Docs/Conventions/SwiftUI.md). Follow the project's extraction criteria, including its allowance for simple private view properties and functions, ahead of generic skill recommendations.
- Keep task progress and future priorities in Issues or task documents. This file contains durable working instructions, not a roadmap or an inventory of installed skills.
- Before implementing a substantial feature or decision-shaping fix, or reviewing work with task records, read [the task documentation workflow](Docs/Tasks/README.md). Use it to decide when to keep a plan and result, and load the relevant existing records; small changes do not require a task folder.

## Validation and Apple Tools

- Prefer the native `xcode` MCP for operations it exposes. Use `xcodebuildmcp` when the native tool is unavailable, fails, or lacks the operation; use direct Xcode commands only when neither MCP can perform it.
- Before the first build, test, run, Preview, or device operation, read [the Xcode workflow](Docs/agent-workflows.md#xcode-project-context) and reconcile the selected tool with `.xcodebuildmcp/config.yaml`. Do not assume either tool has the correct project, scheme, or Simulator already selected.
- Use `./Scripts/format.sh --check` and `./Scripts/lint.sh` for Swift formatting and strict lint. `./Scripts/validate_data_schemas.sh` provides data schema validation.
- `./Scripts/test.sh` and `./Scripts/build_apps.sh` define the project's Simulator test and app-build commands; `./Scripts/ci.sh` assembles the full CI workflow. Follow the MCP preference above for interactive build/test work. Do not treat a generic host `swift build` or `swift test` as validation of the iOS app and UI targets.
- Prefer the sosumi MCP for Apple Developer Documentation, Human Interface Guidelines, and video transcripts. Use other sources when the needed material is unavailable there. Verify current API behavior when it affects implementation or review.

## Task-Specific Workflows

- For SwiftUI work, prefer the project-local `swiftui-pro` skill; for concurrency work, `swift-concurrency-pro`; for SwiftData work, `swiftdata-pro`. Load only the relevant guidance.
- For a requested change or PR review, use [review-changes](.agents/skills/review-changes/SKILL.md). Its [Chinese counterpart](.agents/skills/review-changes/SKILL.zh-CN.md) is for the maintainer. Ordinary implementation does not itself trigger a parallel review run.
- For publishing a remote full SwiftData seed store, use `publish-full-seed-store`. For worktree cleanup, use `cleaning-merged-pr-worktrees` when the PR is merged/closed or its remote branch is gone; otherwise use `worktree-cleanup`.
- For viewing or operating Simulator in the Codex browser, read [the repository browser workflow](Docs/agent-workflows.md#simulator-in-codex-browser) and use `ios-simulator-browser` with the available in-app browser tools. Follow the repository's proxy and Simulator-selection requirements in that workflow.
