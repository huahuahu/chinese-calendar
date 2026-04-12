# AGENTS.md

This repository hosts a Swift project for browsing the traditional Chinese calendar on iOS and macOS.

## Goals

- Build a shared Swift codebase for iOS and macOS.
- Import Chinese calendar source data from [ytliu0/ChineseCalendar](https://github.com/ytliu0/ChineseCalendar).
- Present historical calendar data in a clean browsing experience.

## Current Structure

- `Package.swift`: Shared Swift Package definition.
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

## Common Commands

- `swift build`
- `swift test`
- `git status --short`

## Near-Term Priorities

1. Add importer scripts for the upstream Chinese calendar dataset.
2. Define stable app-side data models and serialization format.
3. Build a calendar browsing UI backed by real imported data.
4. Create an Xcode project or workspace that wraps the shared package targets.

## Notes for Codex

- Before adding new modules, check whether the code belongs in an existing shared package target.
- Prefer incremental scaffolding over large speculative implementations.
- When touching data import logic, document the upstream source and output format.

## Installed Agent Resources

- Project-local Codex skill: `./.codex/skills/swiftui-pro`
- Project-local Codex skill: `./.codex/skills/swift-concurrency-pro`
- Project-local Codex skill: `./.codex/skills/swiftdata-pro`
- Upstream Swift agent index reference: `./Docs/AgentReferences/swift-agent-skills/README.md`
- Upstream SwiftAgents reference: `./Docs/AgentReferences/SwiftAgents/AGENTS.upstream.md`

## Swift Agent Guidance

The project keeps its own repository-specific rules above, but also adopts the spirit of Paul Hudson's Swift agent guidance:

- Prefer modern Swift and SwiftUI API over legacy alternatives.
- Favor Swift concurrency and safe state management patterns.
- Avoid third-party dependencies unless there is a clear project need.
- Keep SwiftUI code accessible, testable, and structurally simple.

When a task is primarily about SwiftUI review or generation, prefer using the local `$swiftui-pro` skill.
When a task is primarily about async/await, actor isolation, cancellation, or task structure, prefer `$swift-concurrency-pro`.
When a task is primarily about SwiftData models, predicates, indexing, or CloudKit integration, prefer `$swiftdata-pro`.
