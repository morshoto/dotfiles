---
name: refactor-python
description: Behavior-preserving refactoring of Python code. Restructure, simplify, reduce duplication, improve readability/maintainability, modularity, typing clarity, or testability while keeping public APIs and behavior stable. Use for small, reviewable refactors; not for new features, major rewrites, or intentional behavior changes unless explicitly requested.
---

# Refactor: Python

Perform behavior-preserving refactors to Python codebases with an emphasis on clarity, safety, and reviewability.

## Scope

Good fits:

- Simplify complex functions/classes without changing behavior.
- Extract helpers, reduce duplication, improve naming, and improve module boundaries.
- Improve typing where it clarifies interfaces or reduces ambiguity.
- Make code more testable (smaller pure functions, clearer interfaces, dependency injection).

Not a fit (unless explicitly asked):

- New features, new endpoints, new product behavior.
- Major rewrites (framework swaps, async conversions, ORM replacements).
- Architectural overhauls without explicit requirements.
- Fixing tests by changing expectations; flag and ask instead.

## Operating Principles

- Preserve behavior by default; keep public APIs stable (imports, signatures, return types, exceptions, side effects).
- Prefer small, reviewable diffs; avoid mega-diffs and formatting churn.
- Make intent obvious; reduce cognitive load.
- Prove safety; run existing tests/linters if available.

## Workflow

1. Clarify constraints quickly

- Identify the refactor goal (readability, modularity, typing, performance, testability).
- Identify constraints: no behavior changes, backward compatibility, no new deps, Python version, style/lint rules.
- Identify the public surface: CLI commands, exports, stable classes/functions, config files, serialized formats.

2. Baseline the current state

- Locate entry points, critical paths, and existing tests.
- Use existing project commands if present; otherwise default only if configured:
- `python -m pytest`
- `ruff check .`
- `ruff format .` or `black .`
- `mypy .` or `pyright`
- If tools aren’t installed/configured, refactor without inventing new tooling.

3. Plan small, concrete steps

- State what will change (structure) and what will not (behavior & API).
- Order steps by safety: extract helpers, rename internals, consolidate logic, then optional typing.
- List files likely affected and a test strategy.

4. Execute with guardrails

- Mechanical cleanup: remove dead code only if clearly unused and not public.
- Simplify control flow: early returns, reduce nesting, split large functions.
- Improve structure: group helpers, introduce small internal classes/dataclasses if it improves cohesion.
- Improve typing only where it clarifies interfaces; avoid heavy generics unless needed.
- Performance tweaks only if clearly safe and behavior-preserving.

5. Validate

- Re-run tests/linters/types if available.
- Sanity-check behavior: exceptions, logging, ordering, serialization, I/O boundaries.
- Confirm public APIs didn’t change (signatures, import paths, documented behavior).

6. Deliver for review

- Summarize structural changes and explicitly state behavior/API unchanged.
- Call out risk areas and how you mitigated them.
- Report commands run and outcomes.
- Note optional follow-ups you intentionally didn’t do.

## Checklist

- [ ] Behavior preserved (unless user asked otherwise)
- [ ] Public API unchanged
- [ ] Diff is reviewable (no unnecessary formatting churn)
- [ ] Tests pass or clearly reported gaps
- [ ] Lint/format/type checks respected when available
- [ ] Readability improved and complexity/duplication reduced
- [ ] Docstrings/comments updated where structure changed

## Notes

- If the request is ambiguous (“clean this up”), propose 2–3 safe refactor options and choose the least risky.
- If behavior might change, stop and surface the risk before proceeding.
