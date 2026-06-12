---
name: pr-review-comments
description: Fetch unresolved review comments from the GitHub pull request of the current branch. Use when reviewing PRs, addressing feedback, or checking for unresolved discussions.
---

# Get Unresolved PR Review Comments

Fetch and display unresolved review comments from a GitHub pull request in a concise, token-efficient format.

## Instructions

1. Run the fetch script to retrieve unresolved comments from the current branch's PR:

   ```bash
   bash scripts/fetch-comments.sh
   ```

2. The script will:
   - Automatically detect the PR number for the current branch
   - Fetch all review comments using GitHub CLI (`gh`)
   - Filter to show only unresolved comments
   - Format output as markdown

3. Output includes for each comment:
   - File path and line number
   - Comment author
   - Comment body
   - Direct URL to the comment

## Requirements

- Must be on a branch with an associated pull request

## Example output

```
Found 2 review comment(s):

## src/main.ts:42
**reviewer-name**: Consider using const instead of let here
URL: https://github.com/owner/repo/pull/123#discussion_r456789

## src/utils.ts:15
**reviewer-name**: This function needs error handling
URL: https://github.com/owner/repo/pull/123#discussion_r456790
```
