# codex-skills

Custom Codex skills for starting sessions, tracking execution, and folding lessons back into repo instructions.

## Included Skills

### `session-init`

Use this at the start of a repo session or after a handoff. It reads the repo instructions, progress docs, and current state, then gives a compact briefing with the highest-priority next step.

Best for:
- resuming work in an unfamiliar repo,
- getting a quick project briefing before coding,
- biasing startup context toward a user-specified focus area.

### `execution-ledger`

Use this when a repo needs a real execution source of truth in `docs/progress.md`. It reviews the implementation and existing docs, then creates or updates a practical ledger with phases, tasks, status, validation, and handoff notes.

Best for:
- creating a missing `docs/progress.md`,
- refreshing a stale progress ledger,
- turning vague planning notes into an operational task list.

### `agent-retrospective`

Use this near the end of a work session or after a fix/validation pass. It reviews recent repo evidence and updates `AGENTS.md` with durable lessons that should guide future work.

Best for:
- capturing stable workflow lessons,
- tightening repo instructions after bugs or review findings,
- keeping `AGENTS.md` aligned with current reality.

## How To Use

Install these folders into your Codex skills directory so each skill sits at:

```text
$CODEX_HOME/skills/<skill-name>/SKILL.md
```

Then invoke a skill by name in your prompt, or ask for the matching workflow directly. Examples:

```text
Use session-init on this repo.
Use execution-ledger to create docs/progress.md.
Run agent-retrospective and update AGENTS.md with durable lessons.
```

## Repository Layout

```text
agent-retrospective/
execution-ledger/
session-init/
```
