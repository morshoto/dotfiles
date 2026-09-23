---
name: gh-issue-plan
description: Generate implementation-ready plans from GitHub issue numbers by fetching issue data (title, body, labels, assignees, milestone) via the GitHub REST API and producing a structured Markdown plan (goal, scope, requirements, tasks, acceptance criteria, tests, risks, rollout, excerpt). Use when given a GitHub issue number and repository context and asked to plan the work.
---

# GitHub Issue TDD Planning Skill

## Purpose

Investigate a GitHub issue thoroughly and produce a TDD-first implementation plan.
The plan must translate the issue into observable behaviours, failing tests, minimal
implementation steps, refactoring checkpoints, and final verification.

Use this skill when the user provides a GitHub issue number, GitHub issue URL, or a
repository context plus issue number and asks for a plan, implementation plan, or
TDD plan.

The output is not a generic implementation plan. It is a test-driven execution plan
that makes the next coding session safe, incremental, and reviewable.

## Core TDD Rule

All logic changes must follow Red-Green-Refactor.

1. **Red** — Write a failing test first and confirm it fails for the expected reason.
2. **Green** — Write the smallest production change that makes the test pass.
3. **Refactor** — Clean up test and production code only while tests are green.

Repeat until every required behaviour is covered.

Never plan production code before identifying the failing test that justifies it.
If no failing test can be described, the implementation step is not ready.

## Workflow

### Phase 1: Fetch Issue Context

Retrieve the full issue context.

Prefer GitHub CLI when available:

```bash
gh issue view <number> --repo <owner>/<repo> --json \
  title,body,comments,labels,state,assignees,milestone,url
```

If hierarchy, issue type, or project metadata is relevant, use GraphQL:

```bash
gh api graphql -f query='{
  repository(owner: "<owner>", name: "<repo>") {
    issue(number: <NUMBER>) {
      id
      number
      title
      body
      url
      state
      labels(first: 20) { nodes { name } }
      assignees(first: 10) { nodes { login } }
      milestone { title dueOn }
      issueType { id name }
      subIssues(first: 20) { nodes { number title state } }
      parentIssue { number title }
      comments(first: 50) { nodes { author { login } body createdAt } }
    }
  }
}'
```

Extract:

- Title, body, URL, state
- Labels, assignees, milestone
- Comments that clarify requirements or edge cases
- Parent issue and sub-issues when available
- Issue type from title prefix, labels, and GitHub issue type

Classify the issue:

- **Bug**: reproduction steps, actual result, expected result, environment, logs, screenshots, regression scope
- **Feature**: user-visible behaviours, acceptance criteria, constraints, non-goals
- **Task/Refactor**: intended change, invariants to preserve, migration or cleanup requirements

### Phase 2: Convert Issue to Behaviour Inventory

Before exploring implementation details, rewrite the issue as behaviours that can be
tested.

For each behaviour, define:

- User/system action
- Expected observable result
- Boundary or edge cases
- Existing behaviour that must not regress
- Likely test level: unit, widget/component, integration, e2e, contract, or snapshot

For bugs, always include a regression behaviour that reproduces the reported failure.
For features, split acceptance criteria into the smallest independently testable behaviours.
For refactors, define characterization tests or existing test coverage that proves behaviour is preserved.

### Phase 3: Explore Codebase for Test Seams First

Search the codebase to identify where behaviours should be tested before deciding
where production code should change.

#### For Bugs

1. Search for terms from the issue: error messages, screen names, component names, method names, log output.
2. Locate existing tests around the failing behaviour.
3. Identify the smallest test seam that can reproduce the bug.
4. Trace the production path only after the test seam is known.
5. Determine why existing tests did not catch the bug.

#### For Features

1. Search for similar behaviours and their tests.
2. Identify existing test patterns, fixtures, factories, mocks, and helpers.
3. Map each new behaviour to the lowest useful test level.
4. Identify production layers likely needed after tests are defined.
5. Prefer public interfaces and user-visible outcomes over implementation details.

#### For Tasks / Refactors

1. Find current tests that describe the existing behaviour.
2. Identify missing characterization tests.
3. Plan refactor steps that keep tests green throughout.
4. Avoid changing behaviour unless the issue explicitly asks for it.

### Phase 4: Analyze TDD Strategy

Determine the safest order of tests and implementation cycles.

Answer these questions before producing the plan:

- What is the first failing test?
- What is the smallest possible production change to make it pass?
- What behaviours should be triangulated with additional tests?
- Which tests are unit-level, and which require integration or UI coverage?
- Which existing tests should be run during each cycle?
- Which full verification command should be run at the end?
- What refactoring opportunities should wait until green?

Use bottom-up implementation order when architecture requires it, but keep each step
anchored to a failing test:

1. Client / data source tests and minimal client changes
2. Repository tests and minimal repository changes
3. BLoC / state management tests and minimal logic changes
4. UI / widget / screen tests and minimal presentation changes
5. Router / integration tests when navigation is affected
6. Final regression and affected-suite verification

### Phase 5: Produce the TDD Plan

The plan must be specific enough that an agent or developer can start with the
first failing test immediately.

Do not produce vague tasks such as “implement feature” or “add tests.”
Every implementation step must be paired with a Red-Green-Refactor cycle.

## Output Template

````markdown
## TDD Plan: [Issue Title] (#[number])

**Type**: Bug | Feature | Task | Refactor
**Issue**: [URL]
**Complexity**: Low | Medium | High
**TDD Entry Point**: [first failing test to write]

---

### Issue Summary

[1-2 sentence summary in your own words after investigation]

### Issue Excerpt

> [short excerpt from the issue body or key comment]

### Scope

**In scope**

- [behaviour/change included]
- [behaviour/change included]

**Out of scope**

- [explicit non-goal]
- [deferred work]

### Behaviour Inventory

| ID  | Behaviour              | Test Level                        | First Test File     | Notes                  |
| --- | ---------------------- | --------------------------------- | ------------------- | ---------------------- |
| B1  | [observable behaviour] | Unit / Widget / Integration / E2E | `path/to/test.dart` | [edge case or fixture] |
| B2  | [observable behaviour] | Unit / Widget / Integration / E2E | `path/to/test.dart` | [edge case or fixture] |

### [Bug Only] Regression Reproduction

- **Reported failure**: [actual result]
- **Expected result**: [expected result]
- **Regression test**: `path/to/test.dart`
- **Failure assertion**: [the assertion that should fail before the fix]
- **Suspected layer**: UI | BLoC | Repository | Client | Unknown
- **Evidence**: [code path, logs, issue comment, or reproduction clue]

### [Feature Only] Acceptance Criteria as Tests

| Acceptance Criterion | Test ID | Test Name                             |
| -------------------- | ------- | ------------------------------------- |
| [criterion]          | B1      | `test name should describe behaviour` |
| [criterion]          | B2      | `test name should describe behaviour` |

### Test-First Implementation Cycles

#### Cycle 1: [smallest behaviour]

**Red**

- Add/modify test: `path/to/test.dart`
- Test name: `[descriptive behaviour name]`
- Expected failure before implementation: [compile error, assertion failure, missing state, missing method, etc.]
- Run: `[focused test command]`

**Green**

- Minimal production file(s):
    - `path/to/file.dart` — [smallest change]
- Do not implement: [nearby tempting work to avoid]
- Run: `[focused test command]`

**Refactor**

- Cleanup allowed only after green:
    - [rename, extract helper, remove duplication, simplify branch]
- Run: `[affected test command]`

#### Cycle 2: [next behaviour]

**Red**

- Add/modify test: `path/to/test.dart`
- Test name: `[descriptive behaviour name]`
- Expected failure before implementation: [why it should fail]
- Run: `[focused test command]`

**Green**

- Minimal production file(s):
    - `path/to/file.dart` — [smallest change]
- Run: `[focused test command]`

**Refactor**

- Cleanup allowed only after green:
    - [safe cleanup]
- Run: `[affected test command]`

### Affected Files

| File                | Action                   | TDD Role | Description                 |
| ------------------- | ------------------------ | -------- | --------------------------- |
| `path/to/test.dart` | Create / Modify          | Red      | [behaviour covered]         |
| `path/to/file.dart` | Create / Modify / Delete | Green    | [minimal production change] |

### Test Commands

**Focused cycle commands**

```bash
[command for first failing test]
[command for affected test file/package]
```
````

**Final verification**

```bash
[full affected suite]
[lint/typecheck/analyze command if applicable]
```

### Refactor Checkpoints

- [checkpoint after Cycle 1]
- [checkpoint after Cycle 2]
- [final cleanup after all behaviours are green]

### Risks and Mitigations

- **Risk**: [risk]
  **Mitigation**: [test or rollout mitigation]
- **Risk**: [risk]
  **Mitigation**: [test or rollout mitigation]

### Rollout / Review Notes

- [migration, feature flag, release note, monitoring, reviewer attention]
- [manual QA note if needed]

### Definition of Done

- [ ] Every behaviour in the inventory has a passing test.
- [ ] The reported bug, if any, has a regression test that fails before the fix.
- [ ] Each production change is justified by a prior failing test.
- [ ] Refactoring was performed only while tests were green.
- [ ] Focused and final verification commands pass.
- [ ] Risks and rollout notes are documented in the PR.

```

## TDD Rules

- Never write or plan production code without a failing test that demands it.
- One behaviour per test. Test names should describe behaviour, not implementation.
- Prefer the smallest useful test. Start with the most direct public interface.
- Keep Green minimal. Fake it first when useful, then triangulate with more tests.
- Refactor only on green. Do not restructure while a test is red.
- Do not delete, weaken, or skip a test merely to make the suite pass.
- Bug fixes must start with a regression test.
- Tests are first-class code: clear names, readable setup, meaningful assertions.
- Duplication in tests is acceptable when it improves clarity.
- Prefer focused tests during the cycle; run broader verification at the end.

## Tool Reference

| Need | Tool | Example |
| --- | --- | --- |
| Fetch issue | `gh issue view` | `gh issue view 142 --repo owner/repo --json title,body,comments,labels,assignees,milestone,url` |
| Issue hierarchy | `gh api graphql` | Parent issue, sub-issues, issue type, project metadata |
| Find files by name | `Glob` | `Glob("**/*video_feed*")` |
| Search code content | `Grep` | `Grep("VideoFeedBloc")` |
| Read source/tests | `Read` | `Read("mobile/test/blocs/video_feed/video_feed_bloc_test.dart")` |
| Analyze Dart code | `mcp__dart__analyze_files` | Analyze affected Dart files/packages |
| Resolve Dart symbols | `mcp__dart__resolve_workspace_symbol` | Look up class, method, or enum definitions |
| Nostr protocol | `mcp__nostr__read_nip` | Check NIP specifications |
| Nostr event kinds | `mcp__nostr__read_kind` | Understand event structure |

## Complexity Guidelines

| Complexity | Criteria |
| --- | --- |
| **Low** | 1-2 behaviours, one layer, 1-3 files, straightforward focused tests |
| **Medium** | 3-6 behaviours, 2-3 layers, 4-10 files, mocks/fixtures needed |
| **High** | 7+ behaviours, multiple layers, protocol/schema changes, migrations, e2e coverage, rollout risk |

## Planning Quality Checklist

Before returning the plan, verify:

- [ ] The first failing test is explicitly named.
- [ ] Each acceptance criterion maps to at least one test.
- [ ] Every implementation task has a Red, Green, and Refactor section.
- [ ] Test commands are concrete, not generic placeholders when project tooling is known.
- [ ] Risks include test-based mitigations.
- [ ] The plan avoids speculative production work not demanded by tests.
```
