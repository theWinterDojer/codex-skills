# codex-skills

Custom Codex skills for starting sessions, tracking execution, and folding lessons back into repo instructions.

This repo also includes a reusable baseline [`AGENTS.md`](./AGENTS.md) intended for placement at `~/.codex/AGENTS.md` as a default global policy.

It also includes [`simple-codex`](./simple-codex/README.md), a minimal bundled harness with the baseline file, core skills, a safe installer, and an interactive wizard.

## Install

Run the installer to download the latest bundle and launch the interactive wizard:

```bash
curl -fsSL https://raw.githubusercontent.com/theWinterDojer/codex-skills/main/install.sh | bash
```

Or clone the repo and run the wizard locally:

```bash
git clone https://github.com/theWinterDojer/codex-skills.git
cd codex-skills/simple-codex
./wizard.sh
```

The wizard previews what it will install and asks before writing anything.

## Included Skills

### `code-review`

Use this after a large change, refactor, or on a fresh repo when you want a pragmatic audit. It reviews recent diffs when they exist, falls back to the current repo when they do not, and looks for correctness risks, conflicting logic, unnecessary code, and low-cost hardening opportunities.

Best for:
- reviewing recent changes before or after a merge,
- auditing a refactor for regressions or conflicting behavior,
- scanning the current repo for pragmatic cleanup without over-engineering.

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

### Use The Baseline `AGENTS.md`

Use the repo's [`AGENTS.md`](./AGENTS.md) as a general default at:

```text
~/.codex/AGENTS.md
```

Recommended layering:

- `~/.codex/AGENTS.md`: global default engineering philosophy and workflow rules.
- `<repo>/AGENTS.md`: project-specific constraints, validation rules, and workflow overrides.
- `agent-retrospective`: evidence-based refinement of the active `AGENTS.md` over time.

Keep the global file broad and durable. Put project-specific requirements in the repository root `AGENTS.md` instead of pushing them into the global baseline.

### Invoke A Skill

Then invoke a skill by name in your prompt, or ask for the matching workflow directly.

Examples:

```text
Use code-review on this repo and audit recent changes.
Use session-init on this repo.
Use execution-ledger to create docs/progress.md.
Run agent-retrospective and update AGENTS.md with durable lessons.
```

You can also be more specific:

```text
Use code-review to review this refactor, look for conflicting logic, and suggest only pragmatic cleanup.
Use session-init and focus on the auth flow.
Use execution-ledger to refresh docs/progress.md from the current implementation.
Use agent-retrospective after this bug fix and add only durable repo rules.
```

### Recommended Operating Model

Use the baseline `AGENTS.md` as the default source of truth for how you generally want agents to work. Then let individual repositories narrow or override those defaults when architecture, release process, or validation expectations differ.

Use `agent-retrospective` to refine instructions conservatively from stable evidence such as repeated review findings, recurring workflow friction, and validated implementation lessons. Avoid turning either global or repo-local `AGENTS.md` files into session logs or one-off preference dumps.

### Packaging `simple-codex`

Treat the repo root as the source of truth for:
- `AGENTS.md`
- the core skill folders
- top-level maintenance docs

Treat `simple-codex/` as the installable bundle. Refresh it after changing the baseline or bundled skills:

```bash
./scripts/build-simple-codex.sh
```

## Repository Layout

```text
scripts/
simple-codex/
code-review/
agent-retrospective/
execution-ledger/
session-init/
```
