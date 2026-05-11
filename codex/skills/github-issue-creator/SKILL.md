---
name: github-issue-creator
description: Creates **GitHub issue (or issues)** using `gh issue create` based on user-provided requests
---

# GitHub Issue Creator

## Overview

This skill creates **exactly one GitHub issue** using `gh issue create`. It is **user-driven**:

- The assistant proceeds to _creation_ only when the user **explicitly asks in English**.
- The issue **body language follows the user** (Japanese is allowed). Do not require translation.
- The issue content must be grounded **only in user-provided text** (no repo scanning, no TODO/FIXME search, no reading code to infer details).
- The assistant must ask for **final approval** before running `gh issue create`.
- Labels are **chosen by the agent**, ideally by checking existing labels via `gh`.

## When to Use

- When the user asks in English: “Create an issue for this”
- When the user wants **one consolidated issue** rather than multiple tickets

## Workflow

1. Confirm target repo and constraints (repo, intent for title, any must-have labels)
2. Determine repository context via `gh` (if not explicitly provided)
3. Draft **one** issue from the user’s provided text (language follows user)
4. Choose labels (best effort) by inspecting existing labels (`gh label list`)
5. Present the draft (title/labels/body) for final approval
6. Create the issue via `gh issue create`
7. Return the created issue URL

## Step 1: Confirm target repo and constraints

If unclear, ask the user (or use reasonable defaults where possible):

- Target repository (`OWNER/REPO`)
- Whether to file in the current repo context (if running inside a repo)
- Any required labels or conventions (optional)

## Step 2: Determine repository owner/context via `gh`

Prefer detection over guessing.

- Current repo:
    - `gh repo view --json nameWithOwner -q .nameWithOwner`

- Optional extra context:
    - `gh repo view --json url,owner,name -q '{owner: .owner.login, name: .name, url: .url}'`

If detection fails, ask the user for `OWNER/REPO`, but **continue drafting**.

## Step 3: Input handling (single issue, user text only)

**Prohibited**

- Searching the repository (`rg`/`grep`) or extracting TODO/FIXME automatically
- Reading code to infer missing context or invent details

**Do**

- Consolidate the user’s provided text into **one** issue
- Deduplicate and adjust granularity without splitting into multiple issues
- Mark missing details as **“Needs confirmation”** rather than guessing

## Step 4: Labels (agent-decided, best effort)

- Try to list existing labels:
    - `gh label list --limit 200`

- Select a minimal, high-signal set of labels that already exist (e.g., type + priority if available)

**Fallback (network/auth/permission failure)**

- Do not block drafting.
- Do not invent label names.
- Create the issue **without labels**, unless the user explicitly provided label names.

## Step 5: Issue body template (language follows user)

Use the user’s language for the body. Base content only on user-provided text.

```
## Summary

## Context / Motivation

## Details
- User request:
  - ...

## Acceptance Criteria
- ...

## Open Questions / Needs Confirmation
- ...
```

## Step 6: Create the issue

- Prefer `--body-file` for clean formatting
- Use `--repo OWNER/REPO` if not in-repo

Example:

- `gh issue create --repo OWNER/REPO --title "..." --body-file /tmp/issue.md --label "..."`

## Safety / Notes

- Do not create the issue without explicit user approval.
- Do not add facts not stated in user-provided text.
- If GitHub is unreachable or `gh` is not authenticated:
    - Still provide the final draft and the exact `gh issue create` command the user can run locally.
    - Do not claim the issue was created.
- If you encounter `could not add label` errors, do not block issue creation. Create the issue without labels and inform the user about the label issue separately.
