#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_ROOT="$REPO_ROOT/GodotProject"
PATCH_FILE="$GODOT_ROOT/addons/AdmobPlugin/android-patches/custom-banner-v5.1.patch"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

git clone --depth 1 --branch v5.1 https://github.com/godot-sdk-integrations/godot-admob.git "$BUILD_DIR/godot-admob"
patch -p1 -d "$BUILD_DIR/godot-admob" < "$PATCH_FILE"

(
	cd "$BUILD_DIR/godot-admob/android"
	./gradlew :admob:assembleDebug :admob:assembleRelease
)

cp "$BUILD_DIR/godot-admob/android/admob/build/outputs/aar/AdmobPlugin-debug.aar" \
	"$GODOT_ROOT/addons/AdmobPlugin/bin/debug/AdmobPlugin-debug.aar"
cp "$BUILD_DIR/godot-admob/android/admob/build/outputs/aar/AdmobPlugin-release.aar" \
	"$GODOT_ROOT/addons/AdmobPlugin/bin/release/AdmobPlugin-release.aar"
echo "Custom-size AdMob plugin AARs installed. Reopen the Godot project before exporting Android."
