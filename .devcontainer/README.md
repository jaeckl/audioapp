# Dev Container

Reproducible environment for Flutter + Android + JUCE/C++ development.

## Contents

- Ubuntu 22.04 base
- JDK 17, CMake, Ninja, Clang
- Android SDK (platform 35, build-tools 35.0.0, NDK 27.2)
- Flutter SDK (pinned in Dockerfile)

## Environment variables

| Variable | Path |
|----------|------|
| `FLUTTER_HOME` | `/opt/flutter` |
| `ANDROID_HOME` | `/opt/android-sdk` |
| `ANDROID_SDK_ROOT` | `/opt/android-sdk` |
| `JAVA_HOME` | `/usr/lib/jvm/java-17-openjdk-amd64` |

## Usage

1. Install [Dev Containers](https://containers.dev/) extension in VS Code / Cursor.
2. **Reopen in Container** from the command palette.
3. Wait for `postCreateCommand.sh` to finish.
4. Run `./tools/doctor.sh`.

## Android device / emulator workflows

### Mode 1 — Build in container, run on host (recommended)

- Build APK inside the container: `./tools/build_android.sh`
- Copy or mount `app_flutter/build/app/outputs/flutter-apk/` to the host.
- Install with host ADB: `adb install -r app-debug.apk`
- Use a **physical device** or **host-managed emulator** (Android Studio on host).

Emulator GPU acceleration inside the container is **not** assumed.

### Mode 2 — Container with ADB (optional)

- Forward host USB or TCP ADB into the container if your setup supports it.
- Mount `/dev/bus/usb` or use `adb connect host.docker.internal:5555`.
- Document your host-specific udev rules; not required for MVP.

## Host requirements

- Docker with sufficient disk (~15 GB for SDK + Flutter cache)
- For on-device testing: USB debugging enabled on Android device
- Windows: WSL2 backend recommended for Dev Containers

## Limitations

- No Xcode / iOS builds
- First `cmake` configure downloads JUCE via network
- `flutter doctor` may warn about Chrome/Linux desktop; Android is the target

## Troubleshooting

- **License errors:** run `yes | sdkmanager --licenses` inside the container.
- **NDK not found:** re-run `./tools/doctor.sh` and verify `ANDROID_HOME`.
- **Gradle slow first build:** normal; subsequent builds use cache.
