---
name: execution-ledger
description: Review the current repo, implementation, existing plans, architecture docs, task lists, and progress notes to create or update docs/progress.md as the execution source of truth. Use when a repo needs a structured execution ledger, when progress.md is missing or stale, when the user wants a plan grounded in current implementation, or when a project needs tracked phases, ordered tasks, validation history, and session handoff notes.
---

# Execution Ledger

Create or maintain `docs/progress.md` as a structured execution ledger grounded in the repo's actual state.

## Goals

Use this skill to make `docs/progress.md` an operational source of truth, not a vague planning note.

The ledger should:
- summarize the product and current implementation,
- capture locked product and architecture decisions,
- define a practical implementation plan,
- track ordered execution tasks,
- record validation evidence,
- preserve useful handoff context,
- stay aligned with the real repo state.

## Workflow

1. Look for an existing `docs/progress.md`.
2. Gather the strongest available evidence:
   - current user instructions,
   - repo `AGENTS.md`,
   - README and architecture docs,
   - open plans or task docs,
   - current implementation and tests,
   - recent commits or diffs when they clarify project direction.
3. Decide whether the work is:
   - create a new ledger,
   - refresh a stale ledger,
   - update a current ledger with recent progress.
4. Build or revise `docs/progress.md` from that evidence.
5. Keep the ledger aligned with the implementation before writing future-looking tasks.
6. Validate any touched docs or metadata with the smallest effective checks.
7. Report what was created or changed, what remains open, and any assumptions that still need confirmation.

## Ledger Structure

Prefer a structure similar to:
- project summary,
- core use,
- product scope,
- technical direction,
- user experience direction when relevant,
- implementation plan by phase,
- ordered execution task list,
- current status,
- QA or validation ledger,
- change log,
- session handoff.

Adapt the exact headings to the repo. Do not force sections that have no evidence or practical value.

## Creation Rules

- If `docs/progress.md` does not exist, create it.
- If a progress ledger exists, update it conservatively rather than rewriting for style.
- Keep the ledger concrete, operational, and current.
- Prefer short declarative statements over narrative prose.
- Write future work as ordered execution steps, not broad aspirations.
- Track only work that is materially relevant to delivery.
- Use stable identifiers for tracked tasks when the project is large enough to benefit from them.
- Keep validation entries tied to actual checks that were run.
- Keep handoff notes short and action-oriented.

## Evidence Rules

- Base product claims on explicit docs, user instructions, or current implementation.
- Base completion status on implemented behavior and validation, not intent.
- Base summaries, counts, manifests, and reported outputs on actual post-operation state when possible.
- When evidence conflicts, prefer:
  1. direct user instructions,
  2. the current implementation and tests,
  3. the most current execution docs,
  4. older docs.
- If the repo contains stale planning language that conflicts with the implementation, update the ledger to reflect current reality and note the change clearly.

## What Not To Do

- Do not turn `docs/progress.md` into a README.
- Do not copy session chatter or raw debugging logs into the ledger.
- Do not preserve dead plans, obsolete architecture, or completed rollout notes that no longer help future work.
- Do not mark work complete without evidence.
- Do not invent roadmap items without repo or user support.
- Do not let the ledger drift away from the implementation.

## Output

When finishing:
- state whether `docs/progress.md` was created or updated,
- summarize the main decisions or task changes recorded,
- list what validation evidence was added or refreshed,
- call out any major assumptions or gaps that still need confirmation.
