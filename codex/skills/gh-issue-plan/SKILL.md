---
name: gh-issue-plan
description: Generate implementation-ready plans from GitHub issue numbers by fetching issue data (title, body, labels, assignees, milestone) via the GitHub REST API and producing a structured Markdown plan (goal, scope, requirements, tasks, acceptance criteria, tests, risks, rollout, excerpt). Use when given a GitHub issue number and repository context and asked to plan the work.
---

# SKILL: gh-issue-plan

## Goal

Generate an issue plan outline for a given GitHub issue number by fetching the issue content via `gh` in new branch.

## Inputs

- `ISSUE_NUMBER` (required): the numeric GitHub issue ID
- `GITHUB_REPO` (optional): preferred repo in `OWNER/REPO` form. **Must be validated**; do not assume it’s correct.

## Key Requirements

1. **Repo detection must be automatic.** If `GITHUB_REPO` is missing or wrong, the skill must discover the correct `OWNER/REPO` on its own.
2. **Always validate** the repo string before using it with `gh issue view`.
3. Create a new branch from updated default branch. Branch name should be descriptive enough to indicate issue title.
4. Do NEVER commit or push anything until user confirms. This skill is only for generating a local plan outline based on the issue content.

---

## Repo Resolution

Use `scripts/resolve_repo.sh` to resolve the repo. It prints `OWNER/REPO` on stdout and logs on stderr.

### Resolution order (implemented in script)

1. If `GITHUB_REPO` is set, validate it.
2. Else (or if validation fails), detect the current repo via `gh repo view`.
3. Else, parse `git remote origin` into `OWNER/REPO`.
4. If still not found, ask the user for `OWNER/REPO`.

```bash
REPO="$(scripts/resolve_repo.sh)" || exit $?
echo "Using repo: $REPO"
```

---

### Workflow

#### 1. Repo Resolution

Use `scripts/resolve_repo.sh` to resolve the repo. It prints `OWNER/REPO` on stdout and logs on stderr.

1. If `GITHUB_REPO` is set, validate it.
2. Else (or if validation fails), detect the current repo via `gh repo view`.
3. Else, parse `git remote origin` into `OWNER/REPO`.
4. If still not found, ask the user for `OWNER/REPO`.

#### 2. Fetch Issue

Use `scripts/fetch_issue.sh` to fetch issue data as JSON:

```bash
ISSUE_JSON="$(scripts/fetch_issue.sh "$REPO" "$ISSUE_NUMBER")"
```

**Error handling**:

- If `gh issue view` returns 404:
    - First, re-check `REPO` resolution and re-validate with `gh repo view "$REPO"`.
    - If repo is valid, the issue may not exist: report that clearly.

- If auth errors occur:
    - Report that access/auth is required, and suggest `gh auth status` / `gh auth login`.

#### 3. Create a new branch from updated default branch

You want to guarantee the branch is based on the **latest** default branch on `origin`, regardless of what branch you’re currently on.

Example for NEW_BRANCH:

- feat/title
- fix/title

```bash
git checkout -b "$NEW_BRANCH"
```

#### 4. Generate Plan

Transform issue into a structured plan. The plan should be implementation-ready and grounded in the issue content.

---

## Output

Produce a plan outline including:

- Summary of issue
- Goals / non-goals
- Proposed approach
- Tasks / milestones
- Risks / open questions
- Testing plan
- Rollout / release notes (if relevant)
