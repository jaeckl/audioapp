#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if command -v dart >/dev/null && [[ -f app_flutter/pubspec.yaml ]]; then
  (cd app_flutter && dart format lib test)
fi

echo "Format complete (C++ clang-format optional — add when engine grows)."
