# Android export — Stage Crash: V-Idol Challenge

Godot **4.5.stable** debug APK export for this Linux box / Luis’s machine.

## Status (2026-10-02 CT)

| Item | Path / value |
|------|----------------|
| **Debug APK** | `/workspace/miku-teto-megaman/build/StageCrash-debug.apk` (~27 MB) |
| Package | `com.luis.stagecrash.vidol` |
| App name | Stage Crash: V-Idol Challenge |
| Orientation | **landscape** (`display/window/handheld/orientation=0`) |
| Arch | `arm64-v8a` only |
| Signing | Godot debug keystore (`androiddebugkey` / `android`) |
| Gradle | **off** (prebuilt template APK) |

Install on a device/emulator: `adb install -r build/StageCrash-debug.apk`

## What’s already on this box

| Dependency | Location |
|------------|----------|
| Godot 4.5 editor | `/workspace/tools/godot` |
| Export templates 4.5.stable | `~/.local/share/godot/export_templates/4.5.stable/` (`android_debug.apk`, etc.) |
| Android SDK | `~/Android/Sdk` (`ANDROID_HOME`) — platforms 35/36, build-tools 35/36, NDK 27.1, cmdline-tools |
| OpenJDK | `/usr/lib/jvm/java-21-openjdk-amd64` (Debian 13; docs say 17+, 21 works) |
| Debug keystore | `~/.local/share/godot/keystores/debug.keystore` |
| Editor settings | `~/.config/godot/editor_settings-4.5.tres` — `java_sdk_path`, `android_sdk_path`, debug keystore filled |
| Preset | `game/export_presets.cfg` → preset **"Android"** |

Project flags required for Android:

- `rendering/textures/vram_compression/import_etc2_astc=true` (export **fails silently** without this)
- `renderer/rendering_method.mobile="mobile"`
- `window/handheld/orientation=0` (landscape)

## One-shot re-export (this box)

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

mkdir -p /workspace/miku-teto-megaman/build
/workspace/tools/godot --headless --path /workspace/miku-teto-megaman/game --export-debug \
  "Android" /workspace/miku-teto-megaman/build/StageCrash-debug.apk
```

Or: `bash /workspace/miku-teto-megaman/scripts/export_android_debug.sh`

## Fresh machine bootstrap (scripted path)

If SDK / JDK / templates are missing:

```bash
# 1) JDK (Debian 13 = OpenJDK 21; Ubuntu 22.04 often openjdk-17-jdk-headless)
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk-headless   # or openjdk-17-jdk-headless
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))

# 2) Command-line Android SDK (if ~/Android/Sdk missing)
mkdir -p "$HOME/Android/Sdk/cmdline-tools"
cd /tmp
curl -L -o cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q cmdtools.zip -d "$HOME/Android/Sdk/cmdline-tools"
mv "$HOME/Android/Sdk/cmdline-tools/cmdline-tools" "$HOME/Android/Sdk/cmdline-tools/latest"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"

# 3) Godot 4.5 Android export templates (must match editor: 4.5.stable)
mkdir -p "$HOME/.local/share/godot/export_templates/4.5.stable"
cd /tmp
curl -L -o Godot_v4.5-stable_export_templates.tpz \
  https://github.com/godotengine/godot-builds/releases/download/4.5-stable/Godot_v4.5-stable_export_templates.tpz
unzip -q Godot_v4.5-stable_export_templates.tpz
cp -a templates/. "$HOME/.local/share/godot/export_templates/4.5.stable/"

# 4) Debug keystore
mkdir -p "$HOME/.local/share/godot/keystores"
keytool -genkeypair -v \
  -keystore "$HOME/.local/share/godot/keystores/debug.keystore" \
  -storepass android -alias androiddebugkey -keypass android \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"

# 5) Point Godot Editor Settings → Export → Android at JAVA_HOME + ANDROID_HOME + keystore
#    (on this box already set in editor_settings-4.5.tres)

# 6) Export (preset "Android" lives in game/export_presets.cfg)
```

## Known non-blockers

- `cannot connect to daemon at tcp:5037` — adb server not running; **export still succeeds**. Start with `adb start-server` only if installing to a device.
- Release / Play Store needs a **release** keystore + usually `gradle_build/use_gradle_build=true` and an installed Android build template (`android_source.zip`).
- Full templates TPZ is ~1.3 GB; after install only the `4.5.stable` folder is required.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `configuration errors:` with empty body | Enable `import_etc2_astc` in Project Settings → Rendering → Textures |
| Missing templates | Install `4.5.stable` templates (version.txt must say `4.5.stable`) |
| apksigner not found | `sdkmanager "build-tools;35.0.0"` |
| Invalid Java SDK path | `java_sdk_path` must be JDK root containing `bin/java` |
