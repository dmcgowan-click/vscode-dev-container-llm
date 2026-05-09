---
name: pr-summary
description: Workflow for producing an AI generated summary for review, then creating a new PR or updating an existing PR with the summary. Also set the title to follow desired format. Triggers include "summarise changes", "produce summary"
author: Douglas McGowan
---

# PR Summary Workflow

Summarise the changes in the active branch and create or update a PR in GitHub with that summary.

## Requirements

- GitHub MCP
- `jq` for JSON parsing
- Repository write permissions (for updating PR headers and summaries)

## Core Workflow

### 1. Produce Summary of Changes

Produce a summary of changes in the active branch. Keep it high level, focusing on the key changes and their impact. Avoid listing every single change. Instead, group related changes together and highlight the most significant ones.

Let the user review the summary first and allow them to suggest changes.

### 2. Update README.md (optional)

Based on the changes found, update the `README.md` file in the repository to reflect any new features, changes, or important information that should be included

Let the user review the changes to the `README.md` file first and allow them to suggest changes.

> **Future Enhancement** Standardize README structure in this skill to ensure consistency across all repos.

### 3. Commit and Push

If the changes are not yet commited and pushed, commit and push them. The commit message should describe only the changes since the last commit

### 4. Create or Update the PR

All operations must use the **active branch** of the current session

#### Search for Existing PR

1. Search by title for open PRs only
2. If exactly one match is found, use that PR
3. If multiple matches are found, list them and ask the user to select the correct one
4. If no matches are found, treat as new PR (see below)

#### Create New PR

Create a new PR from the active branch

1. Create a title for the PR. Format should be : `[TYPE] - [Short Description]`, where:
  - If the word `fix` appears in the PR, `[TYPE]` should be `FIX`
  - If the word `feature` or `feat` appears in the PR, `[TYPE]` should be `FEATURE`
  - If neither, prompt the user if this is a feature or fix
2. Add the summary of changes to the PR description

## Error Handling

### GitHub MCP Unavailable

1. **Stop the workflow immediately**: Do not attempt any further steps
2. Inform the user that the GitHub MCP server is unavailable and must be fixed before continuing.
3. Report as much diagnostic detail as possible, including:
  - The specific error message or failure returned by the MCP server
  - Which MCP tool call failed (e.g, `create_pull_request`, `update_pull_request`, etc)
  - Any connection or authentication errors observed
4. Suggest common fixes: check that the MCP server is running, verify authentication tokens, and review MCP server logs.