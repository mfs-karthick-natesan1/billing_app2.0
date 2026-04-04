#!/usr/bin/env bash
# Build Android APK using credentials from dart_defines.env
# Usage:
#   ./build_apk.sh          # release APK (requires key.properties)
#   ./build_apk.sh debug    # debug APK

set -e

ENV_FILE="$(dirname "$0")/dart_defines.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: dart_defines.env not found. Copy dart_defines.env.example and fill in values."
  exit 1
fi

# Load key=value pairs and build --dart-define flags
DEFINES=""
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  DEFINES="$DEFINES --dart-define=$key=$value"
done < "$ENV_FILE"

MODE="${1:-release}"
echo "Building $MODE APK..."
# shellcheck disable=SC2086
flutter build apk "--$MODE" $DEFINES

echo ""
echo "APK: build/app/outputs/flutter-apk/app-$MODE.apk"
