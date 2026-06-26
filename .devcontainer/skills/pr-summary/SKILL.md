---
name: pr-summary
description: Workflow for producing an AI generated summary for review, then creating a new PR or updating an existing PR with the summary. Also set the title to follow desired format. Triggers include "summarise changes", "produce summary"
author: Douglas McGowan
---

# PR Summary Workflow

Summarise the changes in the active branch and create or update a PR in GitHub with that summary.

> **Implementation Note:** This skill uses a local helper script (`pr-helper.sh`) instead of
> the GitHub MCP server. This was a deliberate switch to improve performance and reduce token
> usage. The helper script wraps `gh` CLI calls, returning only the data needed — avoiding the
> overhead of MCP tool definitions in context, verbose JSON responses, and multi-step reasoning
> about which MCP tool to invoke. Typical savings are 40–60% fewer tokens per PR operation with
> faster wall-clock time due to fewer round-trips.

## Requirements

- `gh` CLI (GitHub CLI) — authenticated with repo access
- `git` — for branch and diff operations
- Repository write permissions (for creating/updating PRs)

## Helper Script

All GitHub interactions are handled by the co-located script:

```
.devcontainer/skills/pr-summary/pr-helper.sh
```

Available commands:

| Command | Purpose |
|---------|---------|
| `pr-helper.sh diff` | Show commits and file changes on active branch vs default |
| `pr-helper.sh find` | Find existing open PR for the current branch |
| `pr-helper.sh create <title> <body>` | Create a new PR |
| `pr-helper.sh update <number> <title> <body>` | Update an existing PR title and body |
| `pr-helper.sh push` | Push current branch to origin |

Run the script via terminal. Pass multi-line body text using shell quoting or heredocs.

## Core Workflow

### 1. Produce Summary of Changes

Run `pr-helper.sh diff` to gather the changes on the active branch.

Produce a summary of changes. Keep it high level, focusing on the key changes and their impact. Avoid listing every single change. Instead, group related changes together and highlight the most significant ones.

Let the user review the summary first and allow them to suggest changes.

### 2. Update README.md (optional)

Based on the changes found, update the `README.md` file in the repository to reflect any new features, changes, or important information that should be included.

Let the user review the changes to the `README.md` file first and allow them to suggest changes.

> **Future Enhancement** Standardize README structure in this skill to ensure consistency across all repos.

### 3. Commit and Push

If the changes are not yet committed and pushed, commit and push them. The commit message should describe only the changes since the last commit.

Use `pr-helper.sh push` to push the branch to origin.

### 4. Create or Update the PR

All operations must use the **active branch** of the current session.

#### Search for Existing PR

Run `pr-helper.sh find` to look for an open PR on the current branch.

1. If a PR is found, use that PR number for updates
2. If no PR is found, treat as new PR (see below)

#### Create New PR

Run `pr-helper.sh create <title> <body>` to create a new PR from the active branch.

1. Create a title for the PR. Format should be: `[TYPE] [Short Description]`, where:
  - Based on the summary, `[TYPE]` should be either `fix:`, `feat:`, or `chore:`
  - If neither, prompt the user if this is a feature or fix
2. Pass the summary of changes as the body argument

#### Update Existing PR

Run `pr-helper.sh update <number> <title> <body>` to update the PR title and description.

Use actual newlines in the body text — not escaped `\n` sequences.

## Error Handling

### gh CLI Unavailable or Unauthenticated

1. **Stop the workflow immediately**: Do not attempt any further steps
2. Inform the user that the `gh` CLI is unavailable or not authenticated
3. Report the specific error message or exit code from the helper script
4. Suggest common fixes:
  - Run `gh auth status` to check authentication
  - Run `gh auth login` to authenticate
  - Ensure `gh` is installed (`which gh`)