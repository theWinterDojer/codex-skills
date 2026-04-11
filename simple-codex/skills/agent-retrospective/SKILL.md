---
name: agent-retrospective
description: Review the current repo state, recent diffs or commits, execution docs, and AGENTS.md to extract durable workflow lessons and update AGENTS.md conservatively. Use when finishing a work session, after a bug-fix or validation pass, during release readiness, or when the user asks to refine repo instructions, coding standards, or lessons learned. If AGENTS.md is missing, create a minimal baseline from explicit user guidance and stable repo evidence.
---

# Agent Retrospective

Turn recent repo experience into durable `AGENTS.md` guidance without polluting the file with one-off history.

## Workflow

1. Read the repo `AGENTS.md` if it exists.
2. Find the repo's execution source of truth if one exists, such as `progress.md`, architecture notes, release docs, or contribution guides.
3. Inspect the most relevant recent evidence:
   - current user instructions,
   - recent diffs or commits,
   - audits and validation results,
   - recurring bugs or workflow friction,
   - product or architecture decisions that became clearly locked.
4. Extract candidate lessons from that evidence.
5. Filter each lesson before editing `AGENTS.md`.
6. Apply only the lessons that pass the filter.
7. Validate the touched documentation or metadata with the smallest effective checks.
8. Report what changed, what you intentionally did not encode, and any remaining open questions.

## Lesson Filter

Keep a lesson only if it is durable and likely to improve future work on this repo.

Prefer lessons that:
- improved correctness,
- reduced repeated workflow friction,
- clarified review expectations,
- locked a stable engineering or product rule,
- prevented a regression more than once,
- improved validation discipline,
- improved documentation hygiene.

Reject lessons that are:
- one-off debugging facts,
- temporary workarounds,
- stale architecture that is no longer active,
- narrow implementation details better kept in code or tests,
- session handoff notes,
- unresolved speculation,
- personal preference with no demonstrated benefit.

## Editing Rules

- Edit `AGENTS.md` conservatively. Prefer tightening or adding a short rule over rewriting the whole file.
- Keep guidance operational and evergreen. Do not turn `AGENTS.md` into a changelog.
- Preserve the file's role separation:
  - evergreen engineering standards belong in general sections,
  - repo-specific constraints belong in project-specific sections.
- If the repo has a baseline template such as `AGENTS_OG.md`, do not modify it unless the user explicitly asks.
- If `AGENTS.md` does not exist, create a minimal baseline with only:
  - engineering philosophy,
  - planning expectations,
  - validation discipline,
  - review or audit expectations,
  - documentation hygiene,
  - question or assumption rules.
- Add repo-specific rules to a new file only when they are supported by explicit user guidance or stable evidence from the repo.

## Evidence Priority

When sources conflict, prefer:
1. direct user instructions in the current session,
2. the repo's declared execution source of truth,
3. the current implementation and tests,
4. recent commits and validation logs,
5. older docs.

If an older `AGENTS.md` rule conflicts with current reality, update the rule instead of preserving stale guidance.

## Output

When finishing:
- summarize the durable lessons you encoded,
- call out any notable lessons you rejected and why,
- state what validation you ran,
- note whether `AGENTS.md` already existed or had to be created.
