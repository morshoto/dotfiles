---
name: github-issue-creator
description: Creates exactly one GitHub issue using `gh issue create` based on user-provided requests, selecting the appropriate `.github/ISSUE_TEMPLATE` when available. Use only user-mentioned labels and milestones.
---

# GitHub Issue Creator

## Overview

This skill creates **exactly one GitHub issue** using `gh issue create`. It is **user-driven**:

- The assistant proceeds to _creation_ only when the user **explicitly asks in English**.
- The issue **body language follows the user** (Japanese is allowed). Do not require translation.
- The issue content must be grounded **only in user-provided text**.
- The assistant must ask for **final approval** before running `gh issue create`.
- Select the most appropriate issue template from `.github/ISSUE_TEMPLATE` when templates are available.
- Do **not** add labels, milestones, assignees, projects, or other metadata unless the user explicitly mentions them.

## When to Use

- When the user asks in English: “Create an issue for this”
- When the user wants **one consolidated issue** rather than multiple tickets
- When the user provides a bug report, feature request, task, refactor request, documentation request, or test request and wants it filed as a GitHub issue

## Workflow

1. Confirm target repo and explicit metadata constraints
2. Determine repository context via `gh` if not explicitly provided
3. Inspect `.github/ISSUE_TEMPLATE` and select the best matching template
4. Draft **one** issue from the user’s provided text, using the selected template when available
5. Present the draft, selected template, and any explicitly requested metadata for final approval
6. Create the issue via `gh issue create`
7. Return the created issue URL

## Step 1: Confirm target repo and explicit metadata constraints

If unclear, ask the user or use reasonable defaults where possible:

- Target repository (`OWNER/REPO`)
- Whether to file in the current repo context if running inside a repo
- User-mentioned title intent
- User-mentioned labels, milestone, assignees, or project fields

Metadata rule:

- Add labels only if the user explicitly mentions labels.
- Add a milestone only if the user explicitly mentions a milestone.
- Add assignees only if the user explicitly mentions assignees.
- Add project fields only if the user explicitly mentions projects.
- Do not infer labels, milestones, assignees, or projects from issue type, template name, title, or content.
- If the user says “use the right labels” or “choose labels for me,” treat that as explicit permission to inspect and choose labels. Otherwise, do not add labels.

## Step 2: Determine repository owner/context via `gh`

Prefer detection over guessing.

- Current repo:
    - `gh repo view --json nameWithOwner -q .nameWithOwner`

- Optional extra context:
    - `gh repo view --json url,owner,name -q '{owner: .owner.login, name: .name, url: .url}'`

If detection fails, ask the user for `OWNER/REPO`, but **continue drafting** when enough request details are available.

## Step 3: Inspect issue templates

Look for issue templates before drafting the body.

Preferred locations:

- `.github/ISSUE_TEMPLATE/*.md`
- `.github/ISSUE_TEMPLATE/*.yml`
- `.github/ISSUE_TEMPLATE/*.yaml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/config.yaml`
- `.github/ISSUE_TEMPLATE.md`

Use local files when running inside the repo:

```bash
find .github/ISSUE_TEMPLATE -maxdepth 1 -type f 2>/dev/null | sort
```

If local files are unavailable but the repo is known, try the GitHub API:

```bash
gh api repos/OWNER/REPO/contents/.github/ISSUE_TEMPLATE --jq '.[].name'
```

Then read candidate templates:

```bash
cat .github/ISSUE_TEMPLATE/<template-file>
# or
gh api repos/OWNER/REPO/contents/.github/ISSUE_TEMPLATE/<template-file> --jq .content | base64 --decode
```

### Template selection rules

Select exactly one template when possible.

Match using:

- Template filename, e.g. `bug_report.md`, `feature_request.yml`, `task.md`
- Template frontmatter `name`, `about`, `title`, `labels`, and `type` fields
- User-provided intent and issue content

Common mappings:

| User request type                  | Preferred template signals                             |
| ---------------------------------- | ------------------------------------------------------ |
| Bug / regression / broken behavior | `bug`, `bug_report`, `defect`, `regression`            |
| Feature / new capability           | `feature`, `feature_request`, `enhancement`, `request` |
| Task / maintenance                 | `task`, `chore`, `maintenance`                         |
| Refactor                           | `refactor`, `cleanup`, `tech debt`                     |
| Docs                               | `docs`, `documentation`                                |
| Test                               | `test`, `testing`, `coverage`                          |
| Question / support                 | `question`, `support`, `help`                          |

If multiple templates plausibly match:

- Choose the most specific template based on the user’s stated request.
- Mention the chosen template in the final approval draft.
- Do not ask unless the ambiguity would materially change required issue fields.

If no template matches:

- Use the generic fallback issue body template in this skill.
- State that no suitable template was found.

### YAML form templates

For GitHub Issue Forms (`.yml` / `.yaml`):

- Follow the form field order.
- Preserve field labels as section headings where practical.
- Fill only from user-provided text.
- For required fields without enough information, write `Needs confirmation`.
- Do not include template-specified default labels or default assignees unless the user explicitly requested them.
- Do not pass template labels to `gh issue create --label` unless explicitly requested by the user.

### Markdown templates

For Markdown templates:

- Preserve the template structure and headings.
- Replace placeholder comments with user-provided content where possible.
- Keep relevant checklist items if present.
- For missing details, write `Needs confirmation`.
- Do not pass template frontmatter labels to `gh issue create --label` unless explicitly requested by the user.

## Step 4: Input handling: single issue, user text only

**Prohibited**

- Searching the repository (`rg`/`grep`) or extracting TODO/FIXME automatically
- Reading code to infer missing context or invent details
- Creating multiple issues unless the user explicitly changes the request
- Adding facts, expected behavior, affected files, reproduction steps, or technical root cause not provided by the user
- Adding labels, milestones, assignees, or projects unless explicitly mentioned by the user

**Do**

- Consolidate the user’s provided text into **one** issue
- Deduplicate and adjust granularity without splitting into multiple issues
- Preserve the user’s language and terminology
- Mark missing details as **“Needs confirmation”** rather than guessing
- Convert vague asks into clear issue prose while staying grounded in user-provided content

## Step 5: Explicit metadata handling

Use metadata only when explicitly requested.

### Labels

If the user explicitly mentions labels, validate them when possible:

```bash
gh label list --limit 200
```

Rules:

- Use only labels the user mentioned or explicitly asked the assistant to choose.
- If a user-mentioned label does not exist, tell the user before creation or create without that label if they approve.
- Do not add type labels such as `bug`, `feature`, or `enhancement` merely because the selected template implies them.
- Do not add labels from template frontmatter unless the user explicitly requested those labels.

### Milestones

If the user explicitly mentions a milestone, validate it when possible:

```bash
gh api repos/OWNER/REPO/milestones --jq '.[].title'
```

Rules:

- Use only the milestone the user mentioned.
- If the milestone cannot be found, ask for confirmation before creating the issue without it.
- Do not infer milestones from release names, labels, branch names, or template defaults.

### Assignees and projects

- Add assignees only when explicitly requested.
- Add projects only when explicitly requested and supported by the available `gh` workflow.
- If `gh issue create` cannot apply a requested field directly, create the issue only after approval and explain any follow-up command needed.

## Step 6: Fallback issue body template

Use this only when no suitable repository template exists or templates cannot be read.

Use the user’s language for the body. Base content only on user-provided text.

```markdown
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

## Step 7: Present final approval draft

Before creation, show:

- Repository
- Selected template file, or `None / fallback`
- Title
- Body
- Labels: only explicitly requested labels, otherwise `None`
- Milestone: only explicitly requested milestone, otherwise `None`
- Assignees/projects: only explicitly requested values, otherwise `None`
- Exact creation command or a close equivalent

Ask for final approval before running `gh issue create`.

## Step 8: Create the issue

- Prefer `--body-file` for clean formatting.
- Use `--repo OWNER/REPO` if not in-repo.
- Include `--label`, `--milestone`, `--assignee`, or project-related commands only when explicitly requested and approved.

Example without metadata:

```bash
gh issue create --repo OWNER/REPO --title "..." --body-file /tmp/issue.md
```

Example with explicitly requested metadata:

```bash
gh issue create --repo OWNER/REPO --title "..." --body-file /tmp/issue.md --label "user-mentioned-label" --milestone "user-mentioned-milestone" --assignee "user-mentioned-assignee"
```

## Safety / Notes

- Do not create the issue without explicit user approval.
- Do not add facts not stated in user-provided text.
- Do not add labels, milestones, assignees, or projects unless explicitly requested by the user.
- Do not treat issue template defaults as permission to add metadata.
- If GitHub is unreachable or `gh` is not authenticated:
    - Still provide the final draft and the exact `gh issue create` command the user can run locally.
    - Do not claim the issue was created.
- If a requested label, milestone, assignee, or project cannot be applied:
    - Do not silently substitute another value.
    - Explain the problem and ask for approval before creating without that metadata.
