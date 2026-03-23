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

### Install With `skill-installer`

If you have the built-in `skill-installer`, install directly from GitHub:

```text
$skill-installer https://github.com/theWinterDojer/codex-skills/tree/main/session-init
$skill-installer https://github.com/theWinterDojer/codex-skills/tree/main/execution-ledger
$skill-installer https://github.com/theWinterDojer/codex-skills/tree/main/agent-retrospective
```

After installing, restart Codex to pick up new skills.

### Install Manually

Copy the skill folder you want into your Codex skills directory:

```text
$CODEX_HOME/skills/session-init/
$CODEX_HOME/skills/execution-ledger/
$CODEX_HOME/skills/agent-retrospective/
```

Each installed skill directory must include its `SKILL.md` file.

### Invoke A Skill

Then invoke a skill by name in your prompt, or ask for the matching workflow directly.

Examples:

```text
Use session-init on this repo.
Use execution-ledger to create docs/progress.md.
Run agent-retrospective and update AGENTS.md with durable lessons.
```

You can also be more specific:

```text
Use session-init and focus on the auth flow.
Use execution-ledger to refresh docs/progress.md from the current implementation.
Use agent-retrospective after this bug fix and add only durable repo rules.
```

## Repository Layout

```text
agent-retrospective/
execution-ledger/
session-init/
```
