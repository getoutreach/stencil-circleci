#!/usr/bin/env bash
# Downloads and install check_config into /usr/local/bin

set -e

if ! command -v check_config >/dev/null 2>&1; then
  tempDir=$(mktemp -d)
  cp ".tool-versions" "$tempDir/"

  pushd "$tempDir" >/dev/null || exit 1
  REPO=getoutreach/stork
  TAG=$(gh release -R "$REPO" list | grep Latest | awk '{ print $1 }')
  echo "Using check_config version: ($TAG)"
  gh release -R "$REPO" download "$TAG" --pattern "stork_*_$(go env GOOS)_$(go env GOARCH).tar.gz"

  echo "" # Fixes issues with output being corrupted in CI
  tar xf stork**.tar.gz
  sudo mv check_config /usr/local/bin/check_config
  sudo chown circleci:circleci /usr/local/bin/check_config
  sudo chmod +x /usr/local/bin/check_config
  popd >/dev/null || exit 1

  rm -rf "$tempDir"
fi
