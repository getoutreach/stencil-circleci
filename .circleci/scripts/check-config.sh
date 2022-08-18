#!/usr/bin/env bash
# Checks if the manifest.yaml and stork.yaml files are valid
set -e

echo " 🛠️ check_config Version"
check_config --version

echo " ℹ️ Running check_config"
check_config

echo " ℹ️ Running 'circleci validate'"
circleci config validate
