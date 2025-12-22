#!/bin/bash

# Usage: bash scripts/rename_apks.sh [debug|release]
# Defaults to release if no argument provided

BUILD_TYPE="${1:-release}"

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$VERSION" | cut -d'+' -f2)

# If no version code in pubspec, use default
if [ -z "$VERSION_CODE" ] || [ "$VERSION_CODE" = "$VERSION_NAME" ]; then
  VERSION_CODE="10"
fi

# Get git SHA for glow
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")

# Get SDK SHA from the local path
SDK_PATH="../spark-sdk"
if [ -d "$SDK_PATH/.git" ]; then
  SDK_SHA=$(cd "$SDK_PATH" && git rev-parse --short HEAD 2>/dev/null || echo "nosdk")
else
  SDK_SHA="nosdk"
fi

# Get current date
BUILD_DATE=$(date +%Y%m%d)

# Navigate to APK output directory
cd build/app/outputs/flutter-apk || exit 1

# Copy and rename APKs based on build type
# Copy and rename APKs based on build type
# Enable nullglob to handle case where no files match a pattern
shopt -s nullglob
files=(app-*-${BUILD_TYPE}.apk app-${BUILD_TYPE}.apk)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "No APKs found for ${BUILD_TYPE} build in $(pwd)"
  exit 1
fi

for f in "${files[@]}"; do
  abi=""
  if [[ "$f" == "app-${BUILD_TYPE}.apk" ]]; then
    abi="universal"
  else
    # Extract ABI from app-<abi>-release.apk
    abi=$(echo "$f" | sed -E "s/app-(.*)-${BUILD_TYPE}\.apk/\1/")
  fi
  
  new_name="glow-${VERSION_NAME}-${VERSION_CODE}-${BUILD_TYPE}-${abi}-${BUILD_DATE}-${GIT_SHA}-sdk@${SDK_SHA}.apk"
  
  cp "$f" "$new_name"
  echo "Created: $new_name (original: $f)"
done

echo "Done! APKs copied & renamed in build/app/outputs/flutter-apk/"
