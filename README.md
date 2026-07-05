# Chinese-date

Swift project for exploring the traditional Chinese calendar on iOS and macOS.

## Quality Gates

- `./Scripts/format.sh`: formats the Swift codebase with SwiftFormat.
- `./Scripts/format.sh --check`: verifies formatting without changing files.
- `./Scripts/lint.sh`: runs SwiftLint in strict mode.
- `./Scripts/test.sh`: runs the Swift Package test suite in `Sources`.
- `./Scripts/ci.sh`: runs format check, lint, and tests in the same order as CI.

## CI

GitHub Actions runs on pushes to `main`, pull requests, and manual dispatch.
The workflow runs on `macos-26` with Xcode 26.4.1, checks formatting, runs linting, and executes `swift test --package-path Sources`.
`swiftformat` and `swiftlint` are installed from pinned GitHub Release versions declared in the workflow, so the CI toolchain stays reproducible.

## Local Tooling

Install the required formatter and linter with Homebrew:

```bash
brew install swiftformat swiftlint
```

For Visual Studio Code Swift navigation and symbol jump, also install:

```bash
brew install xcode-build-server
```

Then generate the Xcode project and build server config once:

```bash
./Scripts/generate_xcodeproj.sh
./Scripts/generate_buildserver_config.sh
```

This repository contains a Swift Package rooted at `Sources` and Xcode app targets under `Apps/`, so VS Code navigation is most reliable when SourceKit-LSP uses the generated `buildServer.json`.

## Agent Configuration

- Canonical project instructions: `./AGENTS.md`
- XcodeBuildMCP project defaults: `./.xcodebuildmcp/config.yaml`
- Project-local skills root: `./.agents/skills`
- Copilot skill metadata: `./.agents/skills/*/agents/copilot.yaml`

## Agent Skills

- Project-local SwiftUI skill: `./.agents/skills/swiftui-pro`
- Project-local Swift Concurrency skill: `./.agents/skills/swift-concurrency-pro`
- Project-local SwiftData skill: `./.agents/skills/swiftdata-pro`
- Project-local worktree cleanup skill: `./.agents/skills/worktree-cleanup`
- Project-local documentation grilling skill: `./.agents/skills/grill-with-docs`

In GitHub Copilot, ask the agent to use `swiftui-pro`, `swift-concurrency-pro`, or `swiftdata-pro` when working on the matching Swift area.
`swift-agent-skills` is a catalog repository, so it is mirrored into this project for reference rather than installed as a directly invokable skill.
