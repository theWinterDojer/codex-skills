# AGENTS.md

This file defines project-specific instructions for this repository.

It should be read together with the global baseline at `~/.codex/AGENTS.md`. When this file is more specific, prefer this file for work in this repo.

## Project Overrides
- Add only repo-specific rules here.
- Narrow or override the global baseline only when the project requires it.
- Keep this file evergreen. Do not use it for session logs, rollout notes, or temporary workarounds.

## Product And Architecture
- Describe stable product requirements that materially affect implementation.
- Describe architecture constraints only when they are active and important to future work.

## Validation
- Describe the smallest effective validation steps for non-trivial changes in this repo.
- Call out any required tests, linters, or manual checks that should not be skipped.

## Documentation
- Document where execution tracking belongs if this repo uses a dedicated progress or rollout doc.
- Keep public README content evergreen and move active handoff details elsewhere.

## Repo Workflow
- Add review priorities, release rules, or deployment constraints only when they are stable and project-specific.
- Prefer explicit rules that reduce repeated mistakes or workflow friction.
