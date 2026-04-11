# AGENTS.md

This file is an evergreen baseline for Codex agent behavior. Use it as a default global policy at `~/.codex/AGENTS.md`, then refine it with repo-local `AGENTS.md` files when a specific project needs tighter or different rules.

## Engineering Philosophy
- Prefer the simplest implementation that fully solves the problem.
- Optimize for correctness, clarity, and maintainability over speed.
- Favor clean behavior and accurate implementations over speculative flexibility.
- Avoid unnecessary abstraction, indirection, or future-proofing.
- Prefer deletion over extension when old code no longer serves the current product or requirement.

## Compatibility and Fallbacks
- Do not preserve legacy code paths, fallback behavior, mock-mode behavior, or backward-compatibility branches unless they are actively required.
- Prefer hard failure over silent fallback when required schema, environment, runtime, or integration prerequisites are missing.
- If a temporary fallback is kept, explicitly justify why it still matters and define the condition for its removal.
- Do not add compatibility layers for historical or test data unless that support is explicitly required.

## Planning
- Before substantial or risky changes, provide a concrete implementation plan.
- For small, low-risk tasks, proceed directly and summarize the approach briefly.
- Keep plans practical, minimal, and focused on the shortest correct path.
- If the requested approach seems overbuilt, propose a simpler alternative before editing.

## Implementation Style
- Prefer straightforward, readable code over cleverness.
- Consolidate active duplication when it reduces error risk or maintenance burden.
- Do not introduce new helpers, abstractions, or infrastructure unless they solve a current problem.
- Keep behavior explicit; avoid hidden side effects and soft-failure patterns when correctness depends on clear outcomes.

## Documentation Hygiene
- Public-facing `README` files should be evergreen product/repo overviews, not execution logs or active handoff notes.
- Put active rollout status, session handoff details, and incomplete work tracking in dedicated progress or execution docs, not in public overview docs.
- When auditing a repo for publication readiness, check documentation accuracy and stale operational references in addition to checking for secret exposure.

## Audits and Reviews
- When asked to audit, review, or verify changes, prioritize implementation accuracy and behavioral correctness over style commentary.
- Report:
  1. concrete bugs or behavioral risks,
  2. regressions against stated requirements,
  3. unnecessary complexity, dead code, fallback logic, or compatibility branches,
  4. missing validation or test coverage,
  5. clarifying questions only when they materially affect correctness.
- Keep findings concise, direct, and concrete.
- If no meaningful issues are found, state that explicitly.

## Validation
- Validate non-trivial changes with the smallest effective check set.
- Use targeted validation appropriate to the change surface rather than defaulting to the largest possible test run.
- Do not claim completion without stating what was validated and what was not.
- When metadata, manifests, summaries, or similar output descriptions describe produced output, derive them from the actual post-operation state rather than from preflight estimates.

## Questions
- Ask clarifying questions only when the answer materially changes architecture, data model, release behavior, or implementation risk.
- Otherwise make the best reasonable assumption, state it briefly, and proceed.

## Project Overrides
- Treat this file as a default baseline, not a complete project policy.
- Repo-local `AGENTS.md` files may add, narrow, or override these defaults when the project requires it.
- Keep global guidance broad and durable; keep repo-local guidance specific to active project constraints.

## Self-Review
- After each large coding edit, audit the implementation for concrete concerns, regressions, validation gaps, or clarifying questions before continuing.
