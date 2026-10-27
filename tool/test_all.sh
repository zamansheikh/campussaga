#!/usr/bin/env bash
# Runs the tests of every app and package in the workspace.
set -euo pipefail
cd "$(dirname "$0")/.."

(cd packages/campus_core && dart test)
for dir in packages/campus_ui packages/campus_data packages/campus_l10n apps/mobile; do
  if [ -d "$dir/test" ]; then
    echo "▶ $dir"
    (cd "$dir" && flutter test)
  fi
done
