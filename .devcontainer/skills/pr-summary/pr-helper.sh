#!/bin/bash
# pr-helper.sh — Helper script for PR summary workflow
# Replaces GitHub MCP calls with direct gh CLI operations for better
# performance and reduced token usage.
#
# Usage: pr-helper.sh <command> [args...]
#
# Commands:
#   diff            Show summary of changes on active branch vs default branch
#   find            Find existing PR for the current branch
#   create <title> <body>   Create a new PR
#   update <number> <title> <body>  Update an existing PR
#   push            Commit and push staged changes

set -euo pipefail

# Determine the default branch (main or master)
get_default_branch() {
  git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p'
}

case "${1:-help}" in
  diff)
    DEFAULT_BRANCH=$(get_default_branch)
    CURRENT_BRANCH=$(git branch --show-current)
    echo "Branch: $CURRENT_BRANCH (comparing against $DEFAULT_BRANCH)"
    echo ""
    echo "=== Commits ==="
    git log --oneline "$DEFAULT_BRANCH".."$CURRENT_BRANCH" 2>/dev/null || echo "(no commits ahead)"
    echo ""
    echo "=== File Changes ==="
    git diff "$DEFAULT_BRANCH"..."$CURRENT_BRANCH" --stat 2>/dev/null || echo "(no diff)"
    ;;

  find)
    CURRENT_BRANCH=$(git branch --show-current)
    gh pr list --head "$CURRENT_BRANCH" --state open --json number,title,url,body --jq '.[0] // empty'
    ;;

  create)
    TITLE="${2:?Error: title required}"
    BODY="${3:?Error: body required}"
    gh pr create --title "$TITLE" --body "$BODY" 2>&1
    ;;

  update)
    PR_NUMBER="${2:?Error: PR number required}"
    TITLE="${3:?Error: title required}"
    BODY="${4:?Error: body required}"
    gh pr edit "$PR_NUMBER" --title "$TITLE" --body "$BODY" 2>&1
    ;;

  push)
    CURRENT_BRANCH=$(git branch --show-current)
    git push origin "$CURRENT_BRANCH" 2>&1
    ;;

  help|*)
    echo "Usage: pr-helper.sh <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  diff                         Show changes on active branch vs default"
    echo "  find                         Find existing open PR for current branch"
    echo "  create <title> <body>        Create a new PR from current branch"
    echo "  update <number> <title> <body>  Update an existing PR"
    echo "  push                         Push current branch to origin"
    exit 1
    ;;
esac
