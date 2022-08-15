#!/usr/bin/env bash
# Downloads and install stencil into /usr/local/bin

set -e

if ! command -v stencil >/dev/null 2>&1; then
  tempDir=$(mktemp -d)
  cp ".tool-versions" "$tempDir/"

  pushd "$tempDir" >/dev/null || exit 1
  REPO=getoutreach/stencil
  TAG=$(gh release -R "$REPO" list | grep Latest | awk '{ print $1 }')
  echo "Using stencil version: ($TAG)"
  gh release -R "$REPO" download "$TAG" --pattern "stencil_*_$(go env GOOS)_$(go env GOARCH).tar.gz"

  echo "" # Fixes issues with output being corrupted in CI
  tar xf stencil**.tar.gz
  sudo mv stencil /usr/local/bin/stencil
  sudo chown circleci:circleci /usr/local/bin/stencil
  sudo chmod +x /usr/local/bin/stencil
  popd >/dev/null || exit 1

  rm -rf "$tempDir"
fi
