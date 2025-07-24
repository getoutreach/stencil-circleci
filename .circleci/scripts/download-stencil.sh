#!/usr/bin/env bash
# Downloads and install stencil into /usr/local/bin

set -e

if ! command -v stencil >/dev/null 2>&1; then
  tempDir=$(mktemp -d)
  cp ".tool-versions" "$tempDir/"

  pushd "$tempDir" >/dev/null || exit 1
  REPO=getoutreach/stencil
  if [[ -n $STENCIL_USE_PRERELEASE ]]; then
    echo "Using prerelease stencil version"
    TAG=$(gh release --repo "$REPO" list --exclude-drafts --json name --jq '.[] | select(.name != "unstable").name' --limit 1)
  else
    echo "Using latest stable stencil version"
    TAG=$(gh release --repo "$REPO" list --json name,isLatest --jq '.[] | select(.isLatest).name')
  fi
  echo "Downloading stencil version: ($TAG)"
  gh release -R "$REPO" download "$TAG" --pattern "stencil_*_$(go env GOOS)_$(go env GOARCH).tar.gz"

  echo "" # Fixes issues with output being corrupted in CI
  tar xf stencil**.tar.gz
  sudo mv stencil /usr/local/bin/stencil
  sudo chown circleci:circleci /usr/local/bin/stencil
  sudo chmod +x /usr/local/bin/stencil
  popd >/dev/null || exit 1

  rm -rf "$tempDir"
fi
