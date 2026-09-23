#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "$*" >&2
}

# Outputs owner/repo on stdout.
# Resolution order:
# 1) GITHUB_REPO env var (validated)
# 2) gh repo view (current repo)
# 3) git remote origin parsing

if [ -n "${GITHUB_REPO:-}" ]; then
  if gh repo view "$GITHUB_REPO" --json nameWithOwner -q .nameWithOwner >/dev/null 2>&1; then
    echo "$GITHUB_REPO"
    exit 0
  else
    log "WARN: GITHUB_REPO is set but invalid or inaccessible: $GITHUB_REPO"
  fi
fi

cur="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
if [ -n "$cur" ]; then
  echo "$cur"
  exit 0
fi

remote="$(git config --get remote.origin.url 2>/dev/null || true)"
if [ -n "$remote" ]; then
  ownerrepo="$(echo "$remote" | sed -E \
    -e 's#^git@github\.com:##' \
    -e 's#^https?://github\.com/##' \
    -e 's#\.git$##')"

  if echo "$ownerrepo" | grep -Eq '^[^/]+/[^/]+$'; then
    if gh repo view "$ownerrepo" --json nameWithOwner -q .nameWithOwner >/dev/null 2>&1; then
      echo "$ownerrepo"
      exit 0
    fi
    log "WARN: Could not validate repo with gh; using parsed remote: $ownerrepo"
    echo "$ownerrepo"
    exit 0
  fi
fi

log "ERROR: Could not determine GitHub repo automatically."
log "Please provide OWNER/REPO."
exit 2
