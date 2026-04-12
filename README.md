# Chinese-date

Swift project for exploring the traditional Chinese calendar on iOS and macOS.

## Quality Gates

- `./Scripts/format.sh`: formats the Swift codebase with SwiftFormat.
- `./Scripts/format.sh --check`: verifies formatting without changing files.
- `./Scripts/lint.sh`: runs SwiftLint in strict mode.
- `./Scripts/test.sh`: runs the Swift Package test suite.
- `./Scripts/ci.sh`: runs format check, lint, and tests in the same order as CI.

## CI

GitHub Actions runs on pushes to `main`, pull requests, and manual dispatch.
The workflow runs on `macos-26` with Xcode 26.4, checks formatting, runs linting, and executes `swift test`.
`swiftformat` and `swiftlint` are installed from pinned GitHub Release versions declared in the workflow, so the CI toolchain stays reproducible.

## Local Tooling

Install the required formatter and linter with Homebrew:

```bash
brew install swiftformat swiftlint
```

## Agent Skills

- Project-local SwiftUI skill: `./.codex/skills/swiftui-pro`
- Project-local Swift Concurrency skill: `./.codex/skills/swift-concurrency-pro`
- Project-local SwiftData skill: `./.codex/skills/swiftdata-pro`
- Swift agent skill index mirror: `./Docs/AgentReferences/swift-agent-skills/README.md`
- SwiftAgents upstream reference: `./Docs/AgentReferences/SwiftAgents/AGENTS.upstream.md`

In Codex, you can invoke the installed SwiftUI skill with `$swiftui-pro`.
In Codex, you can invoke the installed Swift Concurrency skill with `$swift-concurrency-pro`.
In Codex, you can invoke the installed SwiftData skill with `$swiftdata-pro`.
`swift-agent-skills` is a catalog repository, so it is mirrored into this project for reference rather than installed as a directly invokable skill.
