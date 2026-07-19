#!/usr/bin/env bash
# Run on-device audio profile lab benchmark and summarize results.
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-ZY32MCWDJ6}"
SCENARIO="${SCENARIO:-light}"
PLAY_SECONDS="${PLAY_SECONDS:-20}"
SETTLE_SECONDS="${SETTLE_SECONDS:-2}"
SAMPLE_MS="${SAMPLE_MS:-500}"
DEPLOY=0
MANUAL=0

usage() {
  cat <<'EOF'
Usage: measure_audio_profiles.sh [options]

Options:
  -d DEVICE_ID     adb serial (default: ZY32MCWDJ6)
  -s SCENARIO      light|parallel|serial_chain|subtractive
  -p SECONDS       play seconds per profile (default: 20)
  --deploy         build + install APK first
  --manual         capture logcat while you test by hand
  -h               help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) DEVICE_ID="$2"; shift 2 ;;
    -s) SCENARIO="$2"; shift 2 ;;
    -p) PLAY_SECONDS="$2"; shift 2 ;;
    --deploy) DEPLOY=1; shift ;;
    --manual) MANUAL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/app_flutter"
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_DIR="${OUTPUT_DIR:-$LAB_DIR/runs/$TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

ADB="${ANDROID_HOME:-/opt/android-sdk}/platform-tools/adb"
FLUTTER="${FLUTTER_HOME:-/opt/flutter}/bin/flutter"

if ! "$ADB" -s "$DEVICE_ID" get-state >/dev/null 2>&1; then
  echo "adb cannot reach $DEVICE_ID" >&2
  exit 1
fi

if [[ "$DEPLOY" -eq 1 ]]; then
  (cd "$APP_DIR" && "$FLUTTER" build apk --debug && "$FLUTTER" install --debug -d "$DEVICE_ID")
fi

LOGCAT_PATH="$OUTPUT_DIR/logcat.txt"
FLUTTER_LOG_PATH="$OUTPUT_DIR/flutter_test.log"
JSON_PATH="$OUTPUT_DIR/summary.json"
MD_PATH="$OUTPUT_DIR/summary.md"

"$ADB" -s "$DEVICE_ID" logcat -c
"$ADB" -s "$DEVICE_ID" logcat -v time audioapp_engine:E audioapp_engine:I '*:S' >"$LOGCAT_PATH" &
LOGCAT_PID=$!
cleanup() {
  kill "$LOGCAT_PID" 2>/dev/null || true
}
trap cleanup EXIT

if [[ "$MANUAL" -eq 1 ]]; then
  echo "Manual session: play your project on $DEVICE_ID, then press Enter."
  read -r _
else
  (
    cd "$APP_DIR"
    "$FLUTTER" test integration_test/audio_profile_lab_test.dart \
      -d "$DEVICE_ID" \
      --dart-define="LAB_SCENARIO=$SCENARIO" \
      --dart-define="LAB_PLAY_SECONDS=$PLAY_SECONDS" \
      --dart-define="LAB_SETTLE_SECONDS=$SETTLE_SECONDS" \
      --dart-define="LAB_SAMPLE_MS=$SAMPLE_MS" \
      2>&1 | tee "$FLUTTER_LOG_PATH"
  )
fi

sleep 1
python3 "$LAB_DIR/parse_lab_output.py" \
  "$FLUTTER_LOG_PATH" \
  "$LOGCAT_PATH" \
  --output-json "$JSON_PATH" \
  --markdown "$MD_PATH"

echo "Wrote $JSON_PATH"
echo "Wrote $MD_PATH"
