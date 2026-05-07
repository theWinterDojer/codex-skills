# simple-codex

`simple-codex` is a minimal Codex harness.

It gives you:
- a reusable global `AGENTS.md` baseline,
- a small set of core skills,
- a simple installer,
- a clean layering model for global and repo-local instructions.

This folder is the installable bundle. The canonical source files live in the repo root and are copied here by [`../scripts/build-simple-codex.sh`](../scripts/build-simple-codex.sh).

## What It Installs

- `~/.codex/AGENTS.md` if one does not already exist
- `~/.codex/AGENTS.simple-codex.md` when an existing global baseline is preserved
- `~/.codex/skills/code-review/`
- `~/.codex/skills/session-init/`
- `~/.codex/skills/execution-ledger/`
- `~/.codex/skills/agent-retrospective/`
- `~/.codex/simple-codex-manifest.txt`

Optional:
- `<repo>/AGENTS.md` from the repo template when missing
- `<repo>/AGENTS.simple-codex.md` when an existing repo file is preserved

## Layering Model

- `~/.codex/AGENTS.md`: your default engineering philosophy and workflow rules.
- `<repo>/AGENTS.md`: project-specific rules that add to or override the global baseline.
- `agent-retrospective`: the workflow for refining the active `AGENTS.md` conservatively from repeated evidence.

## Included Skills

- `code-review`: review recent changes or the current repo for correctness risks and pragmatic cleanup.
- `session-init`: start a repo session by reading instructions, progress docs, and current state.
- `execution-ledger`: create or refresh `docs/progress.md` as a practical execution source of truth.
- `agent-retrospective`: turn stable implementation and workflow lessons into durable `AGENTS.md` guidance.

## Install

### Option 1: Install Skills Manually

Download each bundled skill folder and copy it into your Codex skills directory:

```text
~/.codex/skills/code-review/
~/.codex/skills/session-init/
~/.codex/skills/execution-ledger/
~/.codex/skills/agent-retrospective/
```

Each folder must include its `SKILL.md` file. You can also review `AGENTS.md` and copy it to `~/.codex/AGENTS.md` if you want the baseline instructions.

### Option 2: Run The Installer URL

Run the installer to download the latest bundle and launch the interactive wizard:

```bash
curl -fsSL https://raw.githubusercontent.com/theWinterDojer/codex-skills/main/install.sh | bash
```

### Option 3: Clone And Run Locally

Clone the repo and run the local wizard:

```bash
git clone https://github.com/theWinterDojer/codex-skills.git
cd codex-skills/simple-codex
./wizard.sh
```

The wizard detects your current Codex environment, previews conflicts, stages candidates instead of overwriting by default, and asks for a final confirmation before writing anything.
It lets you install the global `AGENTS.md` baseline, the simple-codex skills, or both.

If `~/.codex/AGENTS.md` already exists, the wizard asks whether to replace it. The default is to keep your current file and save the simple-codex baseline beside it as `~/.codex/AGENTS.simple-codex.md`.

When bundled skills already exist, the wizard defaults to keeping the installed versions and lets you replace them in one batch or review them one by one.

To uninstall, run the wizard and choose `Uninstall simple-codex`. It removes simple-codex assets only when they still match this bundle. Modified skills or `AGENTS.md` files are kept.

If you are editing this repo and want to refresh the bundle from the root source files:

```bash
../scripts/build-simple-codex.sh
```

Default behavior is symbiotic:
- unrelated existing skills are left alone,
- bundled skill names are installed if missing,
- existing bundled skill names are left alone unless you choose to replace them,
- an existing global `AGENTS.md` is preserved and the simple-codex baseline is staged beside it,
- an existing repo `AGENTS.md` is preserved and the simple-codex repo template is staged beside it.

When files differ, the wizard can show the changes before you decide whether to keep or replace them.

## Files

- [`AGENTS.md`](./AGENTS.md): default global baseline
- [`install.sh`](./install.sh): minimal installer
- [`wizard.sh`](./wizard.sh): interactive install and adoption flow
- [`templates/repo-AGENTS.md`](./templates/repo-AGENTS.md): starter repo-local override file
- [`skills/`](./skills): bundled core skills
- `simple-codex-manifest.txt`: install ownership record written into the target Codex home

## Recommended Use

1. Install the global baseline and skills.
2. Add a repo-local `AGENTS.md` only when a project needs tighter rules.
3. Use `session-init` to start unfamiliar repos.
4. Use `execution-ledger` when a repo needs a real progress ledger.
5. Use `agent-retrospective` to refine instructions from stable evidence, not one-off preferences.

## What An Install Reproduces

Installing `simple-codex` reproduces the bundled baseline and skills shipped by this repo:
- `AGENTS.md` or a staged `AGENTS.simple-codex.md`
- `code-review`
- `session-init`
- `execution-ledger`
- `agent-retrospective`

It does not remove or manage unrelated local configuration, built-in system skills, or custom skills outside the bundled set. It only manages its own packaged skill names and optional staged baseline files.
