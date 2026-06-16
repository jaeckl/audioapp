#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STATUS=0

if [[ -d engine_juce ]]; then
  cmake -S engine_juce -B build/engine -G Ninja -DAUDIOAPP_BUILD_TESTS=ON || STATUS=1
  cmake --build build/engine || STATUS=1
  if [[ -f build/engine/audioapp_engine_tests ]]; then
    build/engine/audioapp_engine_tests || STATUS=1
  fi
fi

if [[ -f app_flutter/pubspec.yaml ]]; then
  (cd app_flutter && flutter test) || STATUS=1
fi

exit $STATUS
