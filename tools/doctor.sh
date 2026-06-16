#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; FAILED=1; }
warn() { echo "[WARN] $*"; }

FAILED=0

echo "=== Mobile DAW Doctor ==="

command -v git >/dev/null && pass "git $(git --version)" || fail "git not found"

if command -v java >/dev/null; then
  pass "java $(java -version 2>&1 | head -1)"
else
  fail "java not found"
fi

command -v cmake >/dev/null && pass "cmake $(cmake --version | head -1)" || fail "cmake not found"
command -v ninja >/dev/null && pass "ninja $(ninja --version)" || fail "ninja not found"

if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}" ]]; then
  pass "ANDROID_HOME=${ANDROID_HOME}"
else
  fail "ANDROID_HOME not set or missing"
fi

if [[ -n "${FLUTTER_HOME:-}" && -d "${FLUTTER_HOME}" ]]; then
  pass "FLUTTER_HOME=${FLUTTER_HOME}"
fi

if command -v flutter >/dev/null; then
  pass "flutter $(flutter --version | head -1)"
  flutter doctor -v || warn "flutter doctor reported issues (see above)"
else
  fail "flutter not in PATH"
fi

if [[ -d engine_juce ]]; then
  echo "--- Configuring JUCE engine (dry configure) ---"
  cmake -S engine_juce -B build/engine -G Ninja -DAUDIOAPP_BUILD_TESTS=OFF || fail "engine CMake configure failed"
  cmake --build build/engine || fail "engine build failed"
  pass "engine_juce configures and builds"
fi

if [[ -f app_flutter/pubspec.yaml ]]; then
  echo "--- Flutter pub get ---"
  (cd app_flutter && flutter pub get) || fail "flutter pub get failed"
  pass "app_flutter dependencies resolved"
fi

echo "=== Summary ==="
if [[ "${FAILED:-0}" -ne 0 ]]; then
  echo "Doctor finished with failures."
  exit 1
fi
echo "Doctor finished OK."
