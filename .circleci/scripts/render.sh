#!/usr/bin/env bash
# Renders the current stencil module
set -e

echo " 🛠️ Stencil Version"
stencil --version

echo " 🔨 Setting up Environment"
moduleDir=$(pwd)
tempDir=$(mktemp -d)
pushd "$tempDir" >/dev/null || exit 1
git init
git config --global user.email "circleci@outreach.io"
git config --global user.name "CircleCI"
git checkout -b main || true
git commit --allow-empty -m "initial commit"

cat >service.yaml <<EOF
name: test
modules:
  - name: github.com/getoutreach/stencil-circleci
replacements:
  github.com/getoutreach/stencil-circleci: 'file://$moduleDir'
arguments:
  releaseOptions:
    enablePrereleases: true
    prereleasesBranch: rc
EOF

echo " 📄 Render Stencil Module"
stencil --skip-update

echo " ℹ️ Running 'circleci validate'"
circleci config validate
