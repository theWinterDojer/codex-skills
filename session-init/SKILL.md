---
name: session-init
description: Initialize a coding session by reading the repo's instructions, execution docs, and current state, then summarize the project and recommend the highest-priority next step. Use when starting work in a repo, when resuming after a handoff, when the user wants a project briefing before coding, or when the user provides a focus area and wants the startup summary biased toward that area.
---

# Session Init

Rebuild working context at the start of a session and give the user a compact, actionable briefing.

## Workflow

1. Read `AGENTS.md` if it exists.
2. Find and read the repo's main execution source of truth if one exists, such as:
   - `docs/progress.md`,
   - roadmap or planning docs,
   - architecture notes,
   - contribution or release docs.
3. Inspect enough repo state to understand the current implementation:
   - current branch and worktree status,
   - recent commits or diffs if useful,
   - key implementation files only as needed,
   - relevant tests or validation artifacts.
4. If the user supplied an extra focus area, bias the review toward that topic.
5. Reply with a concise startup briefing before doing new implementation work.

## Startup Briefing

Prefer this output shape:
1. current state,
2. active constraints or risks,
3. recommended next step,
4. handoff or open items.

Keep the briefing short and operational. Prefer high-signal bullets over long prose.

## Behavior Rules

- Treat repo instructions as governing context, not optional background.
- Treat the repo's execution source of truth as authoritative when it exists, unless the current implementation proves it stale.
- If the repo requires a plan before edits, say so in the startup briefing.
- If there is no clear next step, say what is missing and what should be clarified.
- If the repo is already mid-change, surface that before suggesting new work.
- Prefer the highest-leverage unfinished step rather than a random nearby task.

## Priority Rules

When recommending the next step, prefer:
1. explicit user focus for the current session,
2. blocked or highest-priority unfinished work from the execution doc,
3. correctness or validation gaps,
4. stale docs or instruction drift that could mislead future work,
5. secondary cleanup or polish.

Do not recommend speculative work unless the repo evidence supports it.

## What Not To Do

- Do not start coding before giving the startup briefing.
- Do not reread the entire repo if a few files establish the current state.
- Do not invent a roadmap when the repo has none.
- Do not ignore dirty-worktree state, unresolved handoff notes, or stale execution docs.
- Do not overwhelm the user with a long audit when a short situational readback is enough.

## Output

When finishing:
- summarize the current repo state,
- identify the most relevant constraints,
- recommend the next step and why,
- mention any important handoff context or missing information.
