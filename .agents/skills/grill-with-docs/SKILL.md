---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions.
license: MIT
metadata:
  author: Matt Pocock
  version: "1.1-local"
  source: https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs
---

# Grill with project documentation

Stress-test the requested plan against the project's domain language, implementation, and accepted decisions. This local skill combines the upstream [grilling](https://github.com/mattpocock/skills/tree/main/skills/productivity/grilling) and [domain-modeling](https://github.com/mattpocock/skills/tree/main/skills/engineering/domain-modeling) workflows so it can run without an unavailable `Skill` tool or additional installed skills.

## Read the project before asking

- Resolve paths from the active repository root. Read `AGENTS.md`, `CONTEXT.md`, and relevant documents indexed by `Docs/README.md`.
- Read `Docs/Tasks/README.md` and existing task records when the plan involves a substantial feature or decision. Preserve their established location and naming; Chinese-date uses `CONTEXT.md` for domain language and `Docs/Tasks/` for task decisions.
- Find facts in code, tests, documentation, or available tools. Use independent read-only exploration when useful. Distinguish observed behavior from a proposed change; do not ask the user to supply facts you can inspect.

## Work through decisions in rounds

1. Identify the decisions needed for the requested scope and their prerequisites. Focus on choices that affect behavior, boundaries, acceptance, or meaningful trade-offs.
2. Ask a small numbered round of independent questions whose prerequisites are settled, giving a recommended answer and its consequence for each. If the user prefers one question at a time, follow that preference. Questions that depend on an unanswered decision belong to a later round.
3. When an async user-input tool is available, use it for questions and continue independent fact-finding while waiting. Otherwise ask in the conversation and wait. A pending answer is not acceptance of a recommendation. Interpret a brief “yes” only when its question or recommendation is unambiguous.
4. Incorporate answers, update the remaining decisions, and test them against concrete scenarios. Do not repeatedly reopen settled choices without new evidence.
5. Finish with the agreed decisions, acceptance conditions, unresolved questions, and changed documentation. A request to discuss a plan alone does not authorize implementation; existing explicit implementation authorization does not require another ceremonial approval.

## Refine the domain model when it changes

- Compare terminology with `CONTEXT.md`. When a phrase conflicts with the glossary, show the conflicting definitions and propose a precise term.
- Exercise proposed relationships with realistic edge cases: for example, a date spanning historical attribution boundaries or a navigation request arriving during a pending confirmation. Derive relevant scenarios from the actual plan rather than forcing these examples into every discussion.
- Check claims against callers, data, and tests. Explain whether a mismatch requires correcting the model, changing behavior, or clarifying documentation.
- Once the user resolves a term, update the existing glossary in place using [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md). Do not rename it to upstream's `GLOSSARY.md` or create a competing glossary.
- Keep implementation mechanisms, progress, and unresolved hypotheses out of the glossary. Reading established terminology alone does not require changing the domain model.

## Record accepted decisions

- Update the relevant existing task record as decisions settle. Follow `Docs/Tasks/README.md` for whether a new record is warranted; small discussions do not automatically need a task folder.
- Record durable rationale when a choice is costly to reverse, surprising without context, and the result of a real trade-off. Use [ADR-FORMAT.md](ADR-FORMAT.md) within the project's established records instead of starting a parallel `docs/adr/` hierarchy.
- Clearly distinguish a proposal from an accepted decision. Preserve still-open alternatives and the reason an earlier accepted choice was superseded.
- Keep documentation in the project's language and provide the changed file paths at the end. Do not turn a planning discussion into unrelated code edits or remote publication.
