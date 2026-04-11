---
name: code-review
description: Audit recent code changes or the current repository for correctness, regression risk, conflicting logic, unnecessary code, and pragmatic hardening opportunities. Use when the user asks to review or audit recent changes, inspect a refactor, review a fresh repo, or assess the current codebase for bugs, cleanup, and low-risk improvements without over-engineering.
---

# Code Review

## Overview

Review the strongest available evidence first, then report concrete risks and low-cost improvements. Prefer implementation accuracy, behavior regressions, conflicting logic, dead code, and missing validation over style-only commentary.

## Workflow

1. Determine the review target.
2. Gather the smallest set of repo evidence needed.
3. Inspect the implementation for correctness and maintainability risks.
4. Validate suspicious areas when practical.
5. Report findings first, then open questions, then optional cleanup ideas.

## Determine The Review Target

- If the user asked to review recent changes, inspect staged and unstaged changes first, then review the latest commit by default unless the user specifies a different range.
- If there are no relevant changes, audit the current repo state instead.
- If the user names a focus area, bias the review toward that code path, but still surface cross-cutting risks when they materially affect behavior.

## Gather Evidence

Prefer the highest-signal sources:

- changed files and diffs,
- nearby implementation that the changes depend on,
- tests covering the touched behavior,
- repo instructions and execution docs when they define intended behavior,
- recent commits only when they clarify intent.

Do not read the whole repo by default. Expand only when the evidence suggests a real dependency or risk.

## Review Priorities

Prioritize findings in this order:

1. implementation bugs or behavioral regressions,
2. conflicting logic, duplicated behavior, or stale branches,
3. missing guards, validation, error handling, or tests,
4. unnecessary complexity or dead code,
5. small hardening or optimization opportunities with clear payoff.

Avoid speculative rewrites, broad style commentary, or performance suggestions that are not supported by the code path under review.

## Hardening And Optimization Rules

- Prefer low-complexity improvements that reduce real risk.
- Suggest refactors only when they remove duplication, clarify control flow, or reduce maintenance cost.
- Suggest optimizations only when the code shows a plausible hot path, unnecessary work, or avoidable repeated I/O or allocation.
- If an idea adds architecture, abstractions, or new dependencies without strong evidence, reject it.

## Validation

- Run focused checks when they materially increase confidence: targeted tests, linters, or small reproductions.
- If you cannot validate a suspected issue, label it as a risk or question rather than a confirmed bug.
- Distinguish clearly between observed facts, likely inferences, and open questions.

## Output

When finishing:

- present findings first, ordered by severity, with file references,
- keep each finding concrete: what is wrong, why it matters, and what behavior is affected,
- follow with clarifying questions or assumptions,
- include a short summary of pragmatic hardening or cleanup opportunities,
- state explicitly if no material issues were found,
- mention validation run and any gaps.
- end by stating the recommended next step based on the findings,
- then ask: `What would you like to do next?`

## Review Posture

- Be skeptical of large refactors that claim to simplify things while changing behavior.
- Be willing to say the code is acceptable when no meaningful problems are evident.
- Keep the bar practical: catch bugs, risk, drift, and waste without turning the review into redesign.
