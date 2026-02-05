#!/usr/bin/env bash
# Downloads and install stencil via mise

set -euo pipefail

repoName=getoutreach/stencil

if ! command -v stencil >/dev/null 2>&1; then
  if [[ -n ${STENCIL_USE_PRERELEASE:-} ]]; then
    echo "Using prerelease stencil version"
    repoTag=$(gh release --repo "$repoName" list --exclude-drafts --json name --jq '.[] | select(.name != "unstable").name' --limit 5 | head -n 1)
  else
    echo "Using latest stable stencil version"
    repoTag=$(gh release --repo "$repoName" list --json name,isLatest --jq '.[] | select(.isLatest).name')
  fi
  echo "Installing stencil version: ($repoTag)"
  mise use --global github:"$repoName"@"$repoTag"
fi
