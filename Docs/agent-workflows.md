# Agent Tool Workflows

Read the relevant section when [AGENTS.md](../AGENTS.md) routes a task here. These are repository-specific setup and troubleshooting requirements; project coding rules remain in their shared sources.

## Xcode Project Context

Prefer the native `xcode` MCP whenever it exposes the required operation, including inspection, builds, tests, Preview, diagnostics, and device interaction. Use the third-party `xcodebuildmcp` MCP when that operation is missing, unavailable, or fails. Use direct `xcodebuild` or `xcrun simctl` only when neither MCP can perform the operation, including branch-scoped Simulator lifecycle operations handled by the worktree skills.

Before the first native Xcode build, test, run, Preview, or device operation in a session:

1. Read `sessionDefaults` from `.xcodebuildmcp/config.yaml`. This is shared context for both MCPs; do not assume the native Xcode MCP reads it automatically.
2. Resolve a relative `projectPath` or `workspacePath` from the repository root. Open it with `XcodeOpenWorkspace`.
3. Switch to the configured scheme with `XcodeSwitchScheme` when necessary, and choose the configured run destination by matching `simulatorName`. Use `simulatorId` when the operation accepts a device identifier.

Before the first third-party XcodeBuildMCP build, test, or run:

1. Show its active defaults with `session_show_defaults`.
2. Compare them with the same configuration file. If missing or different, apply `sessionDefaults` with `session_set_defaults`, resolving relative project/workspace paths from the repository root first.

The Xcode project is generated from `project.yml` by `Scripts/generate_xcodeproj.sh`. That script also resolves package dependencies; follow the applicable proxy requirements for network access when running it.

If SwiftPM fails with `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`, retry the affected command with a one-shot Git override:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all <command>
```

Do not change global Git configuration for this workaround. Combine the override with the required proxy environment if the command fetches packages.

## Simulator in Codex Browser

Use the `ios-simulator-browser` skill with the available in-app browser tools. The following repository requirements supplement the skill's general instructions.

- Use the Simulator selected from the shared project defaults. Read `sessionDefaults.simulatorId` from `.xcodebuildmcp/config.yaml` when session-default tools are unavailable; do not choose a different booted Simulator by name.
- `serve-sim` must run without inherited proxy variables. A proxy-launched process can capture the framebuffer while the browser remains at `Connecting...` or reports `control socket connect timeout`. If the package is not cached yet, fetch/cache it in a separate command using the required full proxy environment, then start the actual mirror offline with all proxy variables removed.
- Start a Simulator-scoped, long-running mirror and keep its terminal alive while the browser uses it. Never use an unscoped `serve-sim --kill`:

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

- Open the exact local URL printed by `serve-sim` in the Codex in-app browser. Do not report success until the status is `live`, a real app frame is visible, and one Simulator interaction such as switching tabs has visibly changed the app.
- If the browser reports that its webview did not attach, keep the existing browser binding, create a fresh tab, and retry the local URL. Navigation can replace the tab ID; if a later action says the tab is missing, list tabs and reacquire the current `Simulator - <device name>` tab instead of restarting the mirror.
- If `serve-sim` shows `Connecting...`, inspect its terminal. Framebuffer/encoder-ready messages prove capture started, not that the control socket is usable. Restart the mirror with proxy variables removed as above; after it becomes `live`, browser coordinate clicks can operate the streamed UI.
