#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 REPO ISSUE_NUMBER" >&2
  exit 2
fi

REPO="$1"
ISSUE_NUMBER="$2"

if [ -z "$REPO" ] || [ -z "$ISSUE_NUMBER" ]; then
  echo "ERROR: REPO and ISSUE_NUMBER are required." >&2
  exit 2
fi

gh issue view "$ISSUE_NUMBER" \
  --repo "$REPO" \
  --json title,body,labels,assignees,milestone,state,url,number
