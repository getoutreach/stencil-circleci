#!/usr/bin/env bash
# Renders the current stencil module
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$DIR/../.."

echo " 🛠️ Stencil Version"
stencil --version

echo " 🔨 Setting up Environment"
moduleDir=$(pwd)
tempDir=$(mktemp -d)
pushd "$tempDir" >/dev/null || exit 1
git init --initial-branch=main
git config user.name "CircleCI"
git config user.email "circleci@outreach.io"
cat >.tool-versions <<EOF
## <<Stencil::Block(toolver)>>
$(grep ^golang "$ROOT_DIR/.tool-versions")
$(grep ^nodejs "$ROOT_DIR/.tool-versions")
## <</Stencil::Block>>
EOF
go mod init example.com/stencil-circleci/integration
cat >Makefile <<EOF
fmt:
	@echo "Stub formatter"
EOF
git commit --allow-empty -m "initial commit"

cat >service.yaml <<EOF
name: test
modules:
  - name: github.com/getoutreach/stencil-circleci
  - name: github.com/getoutreach/devbase
    channel: rc
replacements:
  github.com/getoutreach/stencil-circleci: 'file://$moduleDir'
arguments:
  description: "Service description"
  reportingTeam: "foo-bar"
  releaseOptions:
    enablePrereleases: true
    prereleasesBranch: rc
EOF

echo " 📄 Render Stencil Module"
stencil --skip-update

echo " ℹ️ Running 'circleci validate'"
circleci config validate
