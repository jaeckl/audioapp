#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app_flutter"

flutter pub get
flutter build apk --debug

echo "APK: build/app/outputs/flutter-apk/app-debug.apk"
