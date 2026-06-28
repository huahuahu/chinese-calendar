---
name: worktree-setup
description: Creates a branch worktree, creates or reuses a branch-scoped iPhone 17 Pro simulator, then updates XcodeBuildMCP simulator defaults.
license: MIT
metadata:
  author: Tiger Guo
  version: "1.0"
---

Set up an isolated branch workspace for this repository and wire a branch-scoped simulator UUID into XcodeBuildMCP defaults.

## Inputs

- Optional: branch name (for example: `feature/my-change`)
- If branch name is not provided, infer it from user intent:
1. Derive a concise semantic slug from the requested task.
1. Use branch style `type/slug` where `type` is one of `feat`, `fix`, `chore`, `refactor`, `docs`, `test`.
1. Example: "set up worktree skill" -> `chore/worktree-setup`.

## Workflow

1. Resolve paths:
1. Repository root: `/Users/tigerguo/git/Chinese-date`
1. Worktree root: `~/worktrees/chinese-date`
1. Worktree path: `~/worktrees/chinese-date/<sanitized-branchname>`
1. MCP config: `~/worktrees/chinese-date/<sanitized-branchname>/.xcodebuildmcp/config.yaml`
1. Ensure the worktree root directory exists.
1. Create or reuse branch behavior:
1. If the local branch exists, use it.
1. If the local branch does not exist, create it from current `HEAD`.
1. If the branch name contains slashes, replace them with dashes in the worktree directory name (for example: `feature/my-change` -> `feature-my-change`).
1. For worktree creation at `~/worktrees/chinese-date/<sanitized-branchname>`:
1. If a worktree already exists at that path for the same branch, reuse it.
1. If it exists for a different branch, fail with an error.
1. Create or reuse a simulator for this branch:
1. Resolve latest available iOS runtime dynamically.
1. Resolve iPhone 17 Pro device type dynamically.
1. Use simulator name `iPhone 17 Pro (<sanitized-branchname>)`.
1. If a simulator with that exact name already exists, reuse its UUID.
1. Otherwise create it and capture the returned UUID.
1. Update `~/worktrees/chinese-date/<sanitized-branchname>/.xcodebuildmcp/config.yaml`:
1. Set `sessionDefaults.simulatorId` to the new UUID.
1. Ensure `sessionDefaults.simulatorName` is `iPhone 17 Pro (<sanitized-branchname>)`.
1. Validate end state:
1. `git worktree list` contains `~/worktrees/chinese-date/<sanitized-branchname>`.
1. `xcrun simctl list devices` contains created UUID.
1. Config file `sessionDefaults.simulatorId` equals created UUID.
1. Run `make setup` in `~/worktrees/chinese-date/<sanitized-branchname>`.

## Guardrails

- Do not delete existing worktrees or simulators as part of this flow.
- Prefer XcodeBuildMCP for simulator inspection when available; use `xcrun simctl` only for creating the branch-scoped simulator because XcodeBuildMCP does not expose simulator creation.
- Fail fast if runtime or device type cannot be resolved.
- If the config file does not exist, stop and report an error instead of creating it.
- If `sessionDefaults` is missing from config, stop and report instead of writing malformed YAML.
- Prefer YAML-aware edits (`yq`) when available. If unavailable, use a constrained key replacement only for `simulatorId` and `simulatorName`.
- After editing with the fallback method, verify the expected values were written. If replacements do not occur, fail with an error.

## Suggested command sequence

```bash
set -euo pipefail

REPO_ROOT="/Users/tigerguo/git/Chinese-date"
BRANCH_NAME="${1:-}"
if [[ -z "$BRANCH_NAME" ]]; then
  BRANCH_NAME="chore/worktree-setup"
fi
SANITIZED_BRANCH_NAME="${BRANCH_NAME//\//-}"
WORKTREE_ROOT="$HOME/worktrees/chinese-date"
WORKTREE_PATH="$WORKTREE_ROOT/$SANITIZED_BRANCH_NAME"
CONFIG_FILE="$WORKTREE_PATH/.xcodebuildmcp/config.yaml"
SIM_NAME="iPhone 17 Pro ($SANITIZED_BRANCH_NAME)"

mkdir -p "$WORKTREE_ROOT"

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  :
else
  git -C "$REPO_ROOT" branch "$BRANCH_NAME"
fi

if [[ -d "$WORKTREE_PATH" ]]; then
  EXISTING_BRANCH="$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || true)"
  if [[ "$EXISTING_BRANCH" == "$BRANCH_NAME" ]]; then
    :
  else
    echo "Worktree path exists for a different branch: $WORKTREE_PATH ($EXISTING_BRANCH)" >&2
    exit 1
  fi
else
  git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing config file: $CONFIG_FILE" >&2
  exit 1
fi

RUNTIME_ID="$(xcrun simctl list runtimes -j | jq -r '.runtimes[] | select(.identifier | startswith("com.apple.CoreSimulator.SimRuntime.iOS-")) | select(.isAvailable == true) | .identifier' | tail -n 1)"
DEVICE_TYPE_ID="$(xcrun simctl list devicetypes -j | jq -r '.devicetypes[] | select(.name == "iPhone 17 Pro") | .identifier' | head -n 1)"

if [[ -z "$RUNTIME_ID" || -z "$DEVICE_TYPE_ID" ]]; then
  echo "Unable to resolve runtime or iPhone 17 Pro device type." >&2
  exit 1
fi

SIM_UUID="$(xcrun simctl list devices -j | jq -r --arg name "$SIM_NAME" '.devices | to_entries[] | .value[] | select(.name == $name and .isAvailable == true) | .udid' | head -n 1)"
if [[ -z "$SIM_UUID" ]]; then
  SIM_UUID="$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE_ID" "$RUNTIME_ID")"
fi

if command -v yq >/dev/null 2>&1; then
  yq -i '.sessionDefaults.simulatorId = strenv(SIM_UUID)' "$CONFIG_FILE"
  yq -i '.sessionDefaults.simulatorName = strenv(SIM_NAME)' "$CONFIG_FILE"
else
  perl -i -pe 's/^(\s*simulatorId:\s*).*$/$1$ENV{SIM_UUID}/' "$CONFIG_FILE"
  perl -i -pe 's/^(\s*simulatorName:\s*).*$/$1$ENV{SIM_NAME}/' "$CONFIG_FILE"

  grep -F "simulatorId: $SIM_UUID" "$CONFIG_FILE" >/dev/null || {
    echo "Fallback edit did not update simulatorId" >&2
    exit 1
  }
  grep -F "simulatorName: $SIM_NAME" "$CONFIG_FILE" >/dev/null || {
    echo "Fallback edit did not update simulatorName" >&2
    exit 1
  }
fi

git -C "$REPO_ROOT" worktree list | grep -F "$WORKTREE_PATH"
xcrun simctl list devices | grep -F "$SIM_UUID"
grep -n "simulatorId:" "$CONFIG_FILE"

make -C "$WORKTREE_PATH" setup
```

## Output expectations

Provide a concise summary with:

1. Branch and worktree path created/used.
1. New simulator UUID.
1. Final `sessionDefaults.simulatorId` value in config.
1. `make setup` result from the worktree.
