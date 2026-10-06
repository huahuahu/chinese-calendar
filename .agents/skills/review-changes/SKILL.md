---
name: review-changes
description: "Review a scoped Chinese-date change or pull request with specialist subagents, evidence verification, deduplication, and per-agent report files. Use for requested code reviews and pre-merge reviews; ordinary implementation and discussion of review policy do not trigger a review run."
---

# Review Changes

English execution instructions. [中文对照版](SKILL.zh-CN.md) has the same numbered sections and rule IDs for the maintainer. Keep both versions aligned when editing; agents only need to load this version.

## 1. Purpose and boundaries

Find actionable problems in the requested change while minimizing false positives, duplicate feedback, and repeated revision cycles. Review an agreed scope, not the entire repository by default.

Use specialist subagents for independent review lanes when delegation is available. Follow the project's model requirements: use the strongest available reasoning model, without silently substituting a smaller model. Adapt the number of lanes to the change and available concurrency; a narrow change may need only one specialist. If delegation is unavailable, perform the lanes sequentially and disclose that limitation.

Specialist reviewers inspect product code and write only their assigned reports. This skill does not itself authorize product edits, commits, posting comments, requesting remote reviews, pushing, or merging. Honor separate authorization already given by the user. Use subagent tools, not new user-owned chats, for this workflow.

Agent instructions and specialist reports are in English. Write the final `summary.md` and user-facing messages in Chinese, addressing the user as 花花虎. Follow an explicit user language override.

## 2. Shared rule sources

Implementation and review use the same project rules. This skill defines the review process; it must not invent a second coding standard.

Read applicable `AGENTS.md` instructions and the requirement or acceptance criteria. Load further sources only when the change needs them:

| Source, relative to the repository root | When to read it |
| --- | --- |
| `Docs/README.md` | Identify the project convention documents relevant to the change; load only those topics |
| `Docs/Tasks/README.md` and relevant existing task records | Substantial features, decision-shaping fixes, or changes with a recorded plan; accepted decisions, acceptance criteria, and implementation evidence |
| `CONTEXT.md` and relevant `Docs/` domain documents | Domain language, calendar behavior, model boundaries, and accepted design decisions |
| `Docs/Conventions/Common.md` | Code implementation or review; shared conventions for comments and logging |
| `Docs/Conventions/SwiftUI.md` | SwiftUI implementation or review; project rules for view decomposition and display constants |
| `.agents/skills/swiftui-pro/SKILL.md` | SwiftUI generation or review |
| `.agents/skills/swiftdata-pro/SKILL.md` | SwiftData models, relationships, queries, or storage |
| `.agents/skills/swift-concurrency-pro/SKILL.md` | Isolation, task lifetime, cancellation, and async state changes |
| `.xcodebuildmcp/config.yaml` and repository Xcode instructions | Before a build, test, Preview, or Simulator operation |

Apply the user's current requirements ahead of local guidance, and project conventions ahead of generic skill recommendations where they differ. Distinguish mandatory rules from preferences and recommendations. When reporting a rule violation, cite the exact applicable rule and explain why its conditions are met. Verify referenced files and APIs; a name alone is not evidence. If a requirement names an unknown file, resolve it before enforcing it.

## 3. Establish scope and create a run

Before delegation, the coordinator records:

- The request, acceptance criteria (including IDs when present), relevant plans and accepted amendments, included paths, and exclusions. Do not treat draft ideas as accepted requirements or create a retrospective plan just to conduct a review.
- The repository root, comparison mode, resolved base/head commit IDs where applicable, and dirty/untracked state. A PR review uses the PR's actual base and head; record the merge base used for its diff. Do not guess a PR target from the current branch name.
- For working-tree review, the relevant staged and unstaged diffs and included untracked file contents or hashes. Preserve the user's files; do not commit, stash, or reset them to obtain a clean review.
- Applicable rule sources, review lanes, report paths, and existing verification evidence with its tested revision.

If the target is unclear, inspect local state first. Use an unambiguous current change when available and state the scope; otherwise ask one concise question. A clean tree with no identified comparison is not an invitation to audit the whole project.

Create a unique directory under `.output/reviews/<run-id>/round-01/`. `.output/` is already ignored by this repository. Honor a user-specified output directory. Never overwrite another run or round.

```text
context.md
reports/
  domain.md
  ui.md
  data-concurrency.md
summary.md
```

Create report files only for selected lanes. Record skipped lanes and the reason in `context.md`. Per-round review artifacts are excluded from the product diff. Bind reports to the recorded code state; recheck that state before publishing the summary. If the code changes during review, identify affected findings and revalidate them against the new state, or explicitly mark the review stale. Do not mix versions silently.

## 4. Dispatch independent specialists

Select lanes by the risks in the diff. These are starting points, not a requirement to start every lane:

| Lane | Responsibility | Useful specialist guidance |
| --- | --- | --- |
| `domain` | Requirement fulfillment, calendar/date boundaries, state ownership, navigation, unavailable data, and caller contracts | `CONTEXT.md` and relevant domain documents |
| `ui` | SwiftUI state propagation, presentation, accessibility, layout, and the limits of visual/interaction evidence | `swiftui-pro` |
| `data-concurrency` | The relevant subset of SwiftData relationships/migrations, persistence, downloads, isolation, cancellation, and resource lifetime | `swiftdata-pro` and/or `swift-concurrency-pro` |

Split a large lane when it contains independent risks, or replace it with a better-matched lane for scripts, build configuration, or documentation. Assign cross-cutting project rules, such as logging, to the lane owning the changed code. Keep the same rule source for all lanes.

Give each specialist the recorded scope, code state, relevant rule paths, its responsibility, and one exclusive report path. Include rules R1–R10 and the report contract below. Specialists may trace callers and dependencies beyond changed lines, but must explain how a finding relates to the reviewed change. Avoid priming them with another reviewer's conclusions before their initial pass.

The coordinator owns shared build, test, and Simulator operations. Specialists request targeted checks or consume recorded evidence; they must not compete for the same Xcode session or device. Do not run unrelated full suites for documentation or low-impact edits. Follow the repository's tool order and environment rules for checks that are needed.

Wait for every dispatched lane to finish or explicitly record it as incomplete. An absent report, tool failure, or unavailable runtime is not a passing review.

## 5. Finding rules

- **R1 — Evidence:** State a reachable trigger, expected versus actual behavior or an explicit rule mismatch, practical impact, and precise source locations. A trace through the real code can establish a finding; reproduction is valuable but not mandatory for every statically provable defect.
- **R2 — Counterevidence:** Check surrounding code, callers, guards, supported versions, and applicable exceptions. Verify API behavior through the repository's documentation tools when it matters. Naming, intuition, or a confidence score alone is insufficient.
- **R3 — Change attribution:** Distinguish newly introduced or worsened problems from pre-existing ones. Keep unrelated pre-existing issues outside the current must-fix list; explain when the change makes an existing problem reachable.
- **R4 — No quota:** Zero findings is a valid result. Do not manufacture issues to fill a lane. Keep unresolved hypotheses under verification gaps, not confirmed defects.
- **R5 — Rule versus preference:** Cite a mandatory project rule when requiring conformance. Omit personal naming, style, or abstraction preferences by default; include optional suggestions only when requested. Do not label a style preference as a functional defect.
- **R6 — Tool coverage:** Use formatter, lint, compiler, and test results as evidence. Do not duplicate each tool diagnostic as an AI finding. Failed or unrun required checks still belong in the verification status and must not be hidden.
- **R7 — Severity:** P0 is an exceptional, demonstrated critical failure; P1 needs urgent correction; P2 is an actionable defect to fix in normal work; P3 is optional polish. Assess impact separately from certainty. A mandatory rule mismatch can require correction without being a runtime bug. A missing test alone is a coverage gap unless the accepted requirement explicitly requires it.
- **R8 — Deduplication:** One root cause gets one final finding, even when several agents identify it. Preserve contributing report IDs and relevant locations. Resolve contradictory reports from evidence, not majority voting.
- **R9 — Bounded suggestions:** Explain the minimum behavior or invariant a fix must restore. Avoid prescribing a broad rewrite when a local fix can meet the requirement. Reviewers do not modify product code during review.
- **R10 — Verification honesty:** Distinguish source inspection, build, tests, Preview, Simulator interaction, and real-device checks. Compilation or a rendered Preview cannot establish actual interaction correctness. Report incomplete acceptance checks as gaps; do not silently waive them or call the change fully accepted.

## 6. Report contract and coordinator verification

Each specialist writes an English Markdown report with these fields, including for zero findings:

Treat this as required information, not a requirement for a separate heading per field. Link to `context.md` and shared check artifacts for common snapshot metadata and test output; avoid repeating them throughout the report. A zero-finding report should contain compact metadata, a short evidence-based rationale, and coverage limits, without restating every rule.

```text
Lane / assigned scope
Reviewed base/head or working-tree snapshot
Status: complete | incomplete | stale
Rule sources read
Paths and execution paths inspected
Checks performed and results; checks not performed
Findings
  ID: <lane>-001
  Kind: defect | mandatory-rule | optional
  Priority: P0 | P1 | P2 | P3
  Location: repository-relative file and line(s), at the reviewed state
  Trigger and expected/actual behavior
  Impact
  Evidence and counterevidence checked
  Applicable rule citation, if any
  Change attribution: introduced | worsened | pre-existing
  Verification: code-traced | reproduced | unverified
  Minimal correction goal
Verification gaps and coverage limits
```

Keep unverified candidates in the gaps section. Reports contain conclusions and inspectable evidence, not hidden reasoning transcripts. Use stable IDs across rounds for the same issue.

The coordinator reads every report, checks each candidate against the source or relevant test evidence, and deduplicates by root cause. Where a candidate is disputed or especially consequential, use a focused verification agent when that adds value. Its job is to try to confirm or disprove the claim. It writes a separate report; another agreeing opinion without evidence does not confirm a finding.

Produce a Chinese `summary.md` containing:

- Reviewed scope/state and the status of each lane.
- Confirmed findings, sorted by impact, with IDs, source locations, evidence, and the minimum correction goal.
- A clear separation between required corrections, requested optional suggestions, and verification gaps. Keep process or mandatory-rule failures distinct from functional defects.
- A disposition ledger: `open`, `fixed-and-verified`, `rejected`, or `deferred`, with reasons and contributing specialist IDs. A rejection needs counterevidence; a deferral records who accepted the remaining risk or that the decision is still pending. Do not waive requirements on the user's behalf.
- Conformance to the accepted plan, deviations, the verification scope, and any incomplete acceptance criteria, using their IDs when available. If no issue is confirmed, say that no actionable issue was found within the reviewed scope, and retain the coverage limits.

When implementation or task-record maintenance is in scope, the coordinator also updates the associated `001-result.md` with verified conclusions and durable evidence according to `Docs/Tasks/README.md`. A standalone review reports this reconciliation in `summary.md` without changing tracked task records. Specialists still write only their assigned reports.

## 7. Re-review and stopping

After separately authorized fixes, create `round-02/` and later rounds in the same run, record the new code state, and keep previous reports intact. Recheck open findings, and inspect the repair diff as new code for regressions along affected execution paths; do not limit the pass to confirming earlier claims. A substantially changed requirement or unrelated expanded scope starts a new run.

Do not reopen a rejected or fixed finding without new evidence. Suppress new optional polish after the first pass; still report newly discovered material defects or mandatory violations and explain why they apply. There is no fixed minimum number of rounds. Additional broad review needs a reason, such as a changed architecture or newly affected subsystem.

Stop when the requested lanes are accounted for and confirmed findings plus gaps have been reported. In a review-and-fix task, stop when required fixes and relevant verification are complete, or report the remaining blocker precisely. Do not repeat full reviews until someone produces an empty list. When a claim remains unresolved after a targeted verification pass, record the missing evidence or decision and return it instead of cycling agents indefinitely.

## 8. Maintaining this skill

Keep project coding conventions under `Docs/Conventions/`, indexed in `Docs/README.md`. Consolidate short, general rules in `Common.md`; keep detailed topics such as SwiftUI in separate documents. For a new accepted rule, record its scope, required behavior, exceptions, and verification method in the appropriate document, and ensure `AGENTS.md` directs both implementation and review to read it. Module READMEs and skills link to that canonical source instead of duplicating rules. Put only review mechanics here. Promote repeated feedback into a shared rule only after the maintainer accepts it.

Update this file and `SKILL.zh-CN.md` together, preserving section numbers and rule IDs. Evaluate changes with representative diffs, including a no-finding case, and inspect false positives, duplicate findings, and revision cycles rather than rewarding the number of findings.

Background references consulted on 2026-10-06; they explain the design, not additional prerequisites for each run:

- [OpenAI: project instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [OpenAI: subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Google: code review standard](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [Anthropic: cloud review verification and customization](https://code.claude.com/docs/en/code-review)
- [GitHub: focused review instructions and iteration](https://docs.github.com/en/copilot/tutorials/customize-code-review)
