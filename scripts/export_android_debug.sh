#!/usr/bin/env bash
# Export Stage Crash debug APK (Godot 4.5 + Android SDK + JDK).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/game"
OUT="$ROOT/build/StageCrash-debug.apk"
GODOT="${GODOT:-/workspace/tools/godot}"

export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:${PATH:-}"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found: $GODOT" >&2
  exit 1
fi
if [[ ! -d "$ANDROID_HOME/platform-tools" ]]; then
  echo "Android SDK missing platform-tools at $ANDROID_HOME" >&2
  exit 1
fi
if [[ ! -f "$HOME/.local/share/godot/export_templates/4.5.stable/android_debug.apk" ]]; then
  echo "Missing Godot 4.5 Android export templates. See docs/ANDROID_EXPORT.md" >&2
  exit 1
fi

mkdir -p "$ROOT/build"
echo "Exporting debug APK → $OUT"
"$GODOT" --headless --path "$GAME" --export-debug "Android" "$OUT"
ls -lh "$OUT"
