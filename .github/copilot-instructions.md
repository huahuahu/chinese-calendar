# Chinese-date Copilot Instructions

This repository builds a shared Swift codebase for iOS and macOS to browse traditional Chinese calendar data.

## Project Goals

- Keep business logic in shared package targets under `Sources/`.
- Treat `ChineseCalendarCore` as the source of truth for domain models.
- Keep platform-specific behavior in `Apps/iOSApp` and `Apps/macOSApp` only when sharing is not practical.
- Store upstream raw data in `Data/Raw` and generated artifacts in `Data/Processed`.

## Architecture

- Shared package: `Sources/Package.swift`
- Core logic: `Sources/ChineseCalendarCore`
- Data loading/repository abstractions: `Sources/ChineseCalendarData`
- Persistence-related code: `Sources/ChineseCalendarPersistence`
- Shared UI: `Sources/ChineseCalendarUI`
- App entry points: `Apps/iOSApp`, `Apps/macOSApp`
- Import and transformation scripts: `Scripts/ImportChineseCalendar`

## Working Conventions

- Prefer modern Swift, SwiftUI, and Swift concurrency APIs.
- Avoid third-party dependencies unless there is clear need.
- Keep changes incremental and reviewable.
- When adding new code, first check whether an existing shared package target is the right place.
- When touching importer logic, document upstream input and generated output format.

## Useful Commands

- `swift build --package-path Sources`
- `swift test --package-path Sources`
- `make test`

## Repo Skills

Use these workspace skills when relevant:

- `swiftui-pro` for SwiftUI generation/review.
- `swift-concurrency-pro` for async/await, actor isolation, cancellation, and task structure.
- `swiftdata-pro` for SwiftData models, predicates, indexing, and CloudKit-related constraints.
- `worktree-setup` for creating a branch worktree at `~/worktrees/chinese-date/<branchname>`, creating a new iPhone 17 Pro simulator, and updating `.xcodebuildmcp/config.yaml` simulator defaults.
