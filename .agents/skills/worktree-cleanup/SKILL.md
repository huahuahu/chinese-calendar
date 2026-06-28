---
name: worktree-cleanup
description: Safely removes a branch worktree, branch-scoped simulator, local branch, and matching remote branch.
license: MIT
metadata:
  author: Tiger Guo
  version: "1.0"
---

Clean up an isolated branch workspace created for this repository, including its Git worktree, branch-scoped simulator, local branch, and matching `origin` branch when safe.

## Inputs

- Branch name (for example: `feature/my-change`) or worktree path.
- If only a worktree path is provided, derive the branch from that worktree with `git branch --show-current`.
- If no explicit branch or path is provided, infer the branch from user intent only when the target is unambiguous. Otherwise ask the user for the exact branch.
- Optional cleanup scope:
1. Worktree cleanup is always included.
1. Local branch cleanup is included by default.
1. Matching `origin/<branch>` cleanup is included by default when it exists and is safe to delete.
1. Branch-scoped simulator cleanup is included by default when the exact simulator name exists.

## Workflow

1. Resolve paths:
1. Repository root: `/Users/tigerguo/git/Chinese-date`
1. Worktree root: `~/worktrees/chinese-date`
1. If given a branch name, replace slashes with dashes to get `<sanitized-branchname>`.
1. Worktree path: `~/worktrees/chinese-date/<sanitized-branchname>`
1. Simulator name: `iPhone 17 Pro (<sanitized-branchname>)`
1. Resolve the target branch and fail if it is empty, ambiguous, or protected.
1. If the worktree path exists:
1. Confirm it is a Git worktree.
1. Confirm its current branch equals the target branch.
1. Confirm `git status --porcelain` is empty.
1. If the branch has an upstream, confirm it has no commits ahead of upstream.
1. If the branch has no upstream but a matching remote branch exists, confirm it has no commits ahead of `origin/<branch>`.
1. Resolve `origin/HEAD` as the default remote branch, falling back to `origin/main` when available.
1. If deleting the matching `origin/<branch>`, confirm the remote branch is merged into the default remote branch unless the user explicitly requested a force cleanup.
1. Remove the worktree with `git worktree remove <path>`.
1. Delete the local branch with `git branch -d <branch>`. Use `-D` only when the user explicitly requested a force cleanup after seeing the safety warning.
1. Delete the matching remote branch with `git push origin --delete <branch>` when it exists and passed the safety checks.
1. Delete only simulators whose name exactly matches `iPhone 17 Pro (<sanitized-branchname>)`.
1. Run `git worktree prune`.
1. Validate the end state:
1. `git worktree list` no longer contains the worktree path.
1. `git branch --list <branch>` is empty when local branch cleanup was requested.
1. `git branch -r --list origin/<branch>` is empty when remote branch cleanup was requested and the remote branch existed.
1. `xcrun simctl list devices` no longer contains the deleted simulator UUIDs when simulator cleanup was requested.

## Guardrails

- Never delete `main`, `master`, `develop`, `dev`, `release`, or `release/*`.
- Never use `rm -rf` for worktree cleanup. Use `git worktree remove`.
- Never use branch globs or fuzzy branch matches for deletion.
- Never delete a remote branch unless it exactly matches `origin/<branch>`.
- Never delete a simulator unless its name exactly matches `iPhone 17 Pro (<sanitized-branchname>)`.
- Prefer XcodeBuildMCP for simulator inspection when available; use `xcrun simctl` only for shutdown/delete operations because XcodeBuildMCP does not expose branch-scoped simulator deletion.
- Abort if the worktree has uncommitted or untracked changes.
- Abort if the branch has commits ahead of its upstream or matching remote branch, unless the user explicitly requested force cleanup.
- Abort if local branch deletion with `git branch -d` fails, unless the user explicitly requested force cleanup.
- Do not use `git reset --hard`, `git checkout --`, `git clean`, `pkill`, or `killall`.
- If the target branch cannot be inferred with confidence, ask the user for the exact branch name.

## Suggested command sequence

```bash
set -euo pipefail

REPO_ROOT="/Users/tigerguo/git/Chinese-date"
WORKTREE_ROOT="$HOME/worktrees/chinese-date"
TARGET="${1:-}"
BRANCH_NAME="$TARGET"
FORCE_CLEANUP="${FORCE_CLEANUP:-0}"

if [[ -z "$TARGET" ]]; then
  echo "Missing branch name or worktree path. Provide the exact target to clean up." >&2
  exit 1
fi

if [[ -d "$TARGET" ]]; then
  WORKTREE_PATH="$(cd "$TARGET" && pwd -P)"
  BRANCH_NAME="$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || true)"
  if [[ -z "$BRANCH_NAME" ]]; then
    echo "Unable to derive branch from worktree path: $WORKTREE_PATH" >&2
    exit 1
  fi
fi

case "$BRANCH_NAME" in
  main|master|develop|dev|release|release/*)
    echo "Refusing to clean protected branch: $BRANCH_NAME" >&2
    exit 1
    ;;
esac

SANITIZED_BRANCH_NAME="${BRANCH_NAME//\//-}"
WORKTREE_PATH="${WORKTREE_PATH:-$WORKTREE_ROOT/$SANITIZED_BRANCH_NAME}"
SIM_NAME="iPhone 17 Pro ($SANITIZED_BRANCH_NAME)"

if [[ -d "$WORKTREE_PATH" ]]; then
  EXISTING_BRANCH="$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || true)"
  if [[ "$EXISTING_BRANCH" != "$BRANCH_NAME" ]]; then
    echo "Worktree path does not match branch: $WORKTREE_PATH ($EXISTING_BRANCH)" >&2
    exit 1
  fi

  if [[ -n "$(git -C "$WORKTREE_PATH" status --porcelain)" ]]; then
    echo "Worktree has uncommitted or untracked changes; aborting:" >&2
    git -C "$WORKTREE_PATH" status --short >&2
    exit 1
  fi

  if git -C "$WORKTREE_PATH" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    AHEAD_COUNT="$(git -C "$WORKTREE_PATH" rev-list --count '@{u}..HEAD')"
    if [[ "$AHEAD_COUNT" != "0" && "$FORCE_CLEANUP" != "1" ]]; then
      echo "Branch has $AHEAD_COUNT commit(s) ahead of upstream; aborting." >&2
      exit 1
    fi
  elif git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    AHEAD_COUNT="$(git -C "$REPO_ROOT" rev-list --count "origin/$BRANCH_NAME..$BRANCH_NAME")"
    if [[ "$AHEAD_COUNT" != "0" && "$FORCE_CLEANUP" != "1" ]]; then
      echo "Branch has $AHEAD_COUNT commit(s) ahead of origin/$BRANCH_NAME; aborting." >&2
      exit 1
    fi
  fi

  git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH"
else
  echo "No worktree exists at $WORKTREE_PATH; continuing with branch and simulator cleanup."
fi

REMOTE_BRANCH_EXISTS=0
if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
  REMOTE_BRANCH_EXISTS=1
  DEFAULT_REMOTE="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -z "$DEFAULT_REMOTE" && -n "$(git -C "$REPO_ROOT" branch -r --list origin/main)" ]]; then
    DEFAULT_REMOTE="origin/main"
  fi

  if [[ -z "$DEFAULT_REMOTE" && "$FORCE_CLEANUP" != "1" ]]; then
    echo "Unable to resolve default remote branch for remote deletion; aborting." >&2
    exit 1
  fi

  if [[ "$FORCE_CLEANUP" != "1" ]]; then
    if ! git -C "$REPO_ROOT" branch -r --merged "$DEFAULT_REMOTE" --list "origin/$BRANCH_NAME" | grep -F "origin/$BRANCH_NAME" >/dev/null; then
      echo "origin/$BRANCH_NAME is not merged into $DEFAULT_REMOTE; aborting." >&2
      exit 1
    fi
  fi
fi

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  if [[ "$FORCE_CLEANUP" == "1" ]]; then
    git -C "$REPO_ROOT" branch -D "$BRANCH_NAME"
  else
    git -C "$REPO_ROOT" branch -d "$BRANCH_NAME"
  fi
fi

if [[ "$REMOTE_BRANCH_EXISTS" == "1" ]]; then
  git -C "$REPO_ROOT" push origin --delete "$BRANCH_NAME"
fi

SIM_UUIDS="$(xcrun simctl list devices -j | jq -r --arg name "$SIM_NAME" '.devices | to_entries[] | .value[] | select(.name == $name and .isAvailable == true) | .udid')"
if [[ -n "$SIM_UUIDS" ]]; then
  while IFS= read -r SIM_UUID; do
    [[ -z "$SIM_UUID" ]] && continue
    xcrun simctl shutdown "$SIM_UUID" >/dev/null 2>&1 || :
    xcrun simctl delete "$SIM_UUID"
  done <<< "$SIM_UUIDS"
fi

git -C "$REPO_ROOT" worktree prune

git -C "$REPO_ROOT" worktree list | grep -F "$WORKTREE_PATH" >/dev/null && {
  echo "Worktree still exists after cleanup: $WORKTREE_PATH" >&2
  exit 1
}

if git -C "$REPO_ROOT" branch --list "$BRANCH_NAME" | grep -F "$BRANCH_NAME" >/dev/null; then
  echo "Local branch still exists after cleanup: $BRANCH_NAME" >&2
  exit 1
fi

if [[ "$REMOTE_BRANCH_EXISTS" == "1" ]] && git -C "$REPO_ROOT" branch -r --list "origin/$BRANCH_NAME" | grep -F "origin/$BRANCH_NAME" >/dev/null; then
  echo "Remote branch still exists after cleanup: origin/$BRANCH_NAME" >&2
  exit 1
fi

xcrun simctl list devices | grep -F "$SIM_NAME" >/dev/null && {
  echo "Simulator still exists after cleanup: $SIM_NAME" >&2
  exit 1
}
```

## Output expectations

Provide a concise summary with:

1. Branch and worktree path cleaned.
1. Whether the local branch was deleted.
1. Whether the remote branch was deleted or was absent.
1. Deleted simulator UUIDs, or that no matching simulator existed.
1. Any safety check that prevented cleanup.
