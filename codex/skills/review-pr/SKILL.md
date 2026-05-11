---
allowed-tools: Bash(git:*), Bash(gh:*), Read(*.md)
description: 'Review the PR specified in the arguments'
---

Please review $ARGUMENTS.
If no PR URL is specified, identify the PR using the current repository's remote information and current branch.
Alternatively, if the specified PR branch does not match the current branch, please checkout the specified branch.
If any commits or file differences exist, please stop.

### Specific Steps

1.  Retrieve the PR content and current comments using gh commands, then use that information to explain the overall context.
    - Explanation content: The background or issues that led to these changes.
2.  Display a summary for each file addressing the following points:
    - Explain the before/after modification differences.
    - Whether the changes are appropriate for the PR's purpose.
3.  Verify the following points in the codebase:
    - Ensure the code style matches other files.
    - Confirm no bugs arise in files dependent on the reviewed file due to the changes.
4.  Based on the above results, display the final review outcome and any issues raised.
5.  Draft comments for the implementer based on the issues raised, adhering to these conditions (do not send):
    - Maintain respect for the implementer, but keep comments short and concise. Maximum of about 3 lines
    - Preface comments with a label. Example: [must], [want], [imo], [ask], [nits], [info]
    - Prioritize comments specific to the file and clearly indicate where comments should appear
    - Display comments if any of the following cases are found:
        - Implementation does not align with the PR's purpose
    - Security issues exist
    - Code smells are present
    - Unexpected side effects or existing functionality is broken
    - Contains factors causing unnecessary API/DB calls, increased processing time, or memory leaks
    - Organize comments into separate sections for each case:
    - Areas requiring fixes or verification
        - Sections requiring no fix but raising concerns
    - For adding tests, determine test necessity by reviewing the codebase

### Important Notes

- The .github folder is located directly under the project directory
- When retrieving PR information, execute all commands below:
- PR metadata: gh pr view --json title,body,files,url {pr_url}
- PR file diff: gh pr diff {pr_url}
- PR comments: gh pr view --comments {pr_url}
- View comments on specific lines within a PR: gh api repos/{org}/{repository}/pulls/{prNumber}/comments | jq '.[] | {file: .path, user: .user.login, comment:.body}'
- Comment on a specific line in a file:

```bash
  gh api \
   repos/{org}/{repository}/pulls/{prNumber}/comments \
   --raw-field body='[imo]\nThis line could be written a bit more safely. ' \
   -f commit_id=$(git rev-parse HEAD) \
   -f path=‘src/foo/bar.js’ \
   -F line=42 \
   -F side=RIGHT
```

- Checkout to the PR branch: gh pr checkout {pr_url}
- Do not retrieve the author when executing gh commands
- Use polite language in comments and avoid assertive statements. Examples: “It appears that...”, “It may be that...”, “I believe that...”
