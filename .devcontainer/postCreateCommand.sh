#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Write Android local.properties"
FLUTTER_SDK="${FLUTTER_HOME:-$(dirname "$(dirname "$(which flutter)")")}"
ANDROID_SDK="${ANDROID_HOME:-/opt/android-sdk}"
cat > app_flutter/android/local.properties <<EOF
flutter.sdk=${FLUTTER_SDK}
sdk.dir=${ANDROID_SDK}
EOF

echo "==> Flutter precache (android)"
flutter precache --android

echo "==> Flutter pub get"
if [[ -d app_flutter ]]; then
  (cd app_flutter && flutter pub get)
fi

echo "==> Accept Android licenses (if needed)"
yes | sdkmanager --licenses >/dev/null 2>&1 || true

echo "==> Post-create complete. Run: ./tools/doctor.sh"
