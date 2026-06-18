# AGENTS.md

Product and engineering rules live in [AGENT.md](AGENT.md). This file adds notes for
automated agents working in the Cursor Cloud environment.

## Cursor Cloud specific instructions

This is a mobile DAW monorepo: a **Flutter** Android UI (`app_flutter/`), a **JUCE/C++**
audio engine (`engine_juce/`), and an Android JNI **native bridge** (`native_bridge/`).
The "backend" is the local native engine — there is no server.

### No Android emulator / device in cloud

Do **not** try to run the Android app on an emulator or device in this cloud VM:

- The VM has **no KVM / nested virtualization** (`/dev/kvm` absent, no `vmx`/`svm`).
- The emulator rejects `arm64-v8a` images on an x86_64 host, and `x86_64` images only
  run under software TCG, which is too slow and crashes `system_server` (the TCG CPU
  lacks AVX/f16c). It is not a reliable target here.
- There are **no integration/e2e tests** yet (`app_flutter/integration_test/` is just a
  placeholder), so nothing requires a booted device in CI-style runs.

On-device / emulator testing is a **local developer** task (a physical device or a
host-managed, KVM-accelerated emulator). The cloud loop below is headless only.

### Headless dev loop (what works here)

| Unit | Command (from repo root) | Notes |
|------|--------------------------|-------|
| Engine build | `cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++` then `cmake --build build/engine --target audioapp_engine` | Library builds cleanly; first configure fetches JUCE 8.0.4 over the network. |
| Flutter tests | `cd app_flutter && flutter test` | 51 widget/bridge unit tests; engine is mocked via `MethodChannel`. |
| Flutter lint | `cd app_flutter && flutter analyze` | Exits non-zero on pre-existing `info`/`warning` hints; there are **0 errors**. |
| Android APK | `cd app_flutter && flutter build apk --debug` | Full build incl. native engine via NDK; Gradle auto-installs build-tools 34 + CMake 3.22.1 on first run. |

### Engine build/test gotchas (pre-existing, do not "fix" as env work)

- The default `c++`/`cc` alternative is **Clang**, which fails to link libstdc++ here.
  Always configure the host engine with **gcc/g++** (`-DCMAKE_C_COMPILER=gcc
  -DCMAKE_CXX_COMPILER=g++`, or `CC=gcc CXX=g++`). `tools/test_all.sh` and
  `tools/doctor.sh` do not set this, so the engine step in them currently fails.
- The `audioapp_engine_tests` target **cannot link**: all 17 files in
  `engine_juce/tests/` define their own `int main()`, and `lfo_modulation_test.cpp`
  calls a non-existent `getProjectSnapshot()`. Several other tests also string-scan for
  compact JSON (`"type":"track_gain"`) while the engine emits pretty-printed JSON, so
  they fail at runtime. These are repo code issues, not environment problems.
- To exercise engine tests, compile a single test file against the built static lib, e.g.
  `g++ <flags from build/engine/compile_commands.json> engine_juce/tests/<t>.cpp \
  build/engine/libaudioapp_engine.a -lasound -lpthread -ldl -lrt -o /tmp/<t>`.
  Harmless `ALSA … /dev/snd/seq` warnings appear because the VM has no audio device.

### Toolchain locations

- `FLUTTER_HOME=/opt/flutter` (3.32.4, Dart 3.8.1), `ANDROID_HOME=/opt/android-sdk`
  (platform 35, build-tools 35.0.0 + 34.0.0, NDK 26.3.11579264, CMake 3.22.1),
  JDK 17 at `/usr/lib/jvm/java-17-openjdk-amd64`.
- These are on `PATH` via `~/.bashrc`. The Android SDK and JDK paths are also stored in
  Flutter's own config, so `flutter` works without env vars. `local.properties` is
  gitignored and is regenerated automatically by `flutter pub get`.

### Python audio-analysis tools (for audio debugging)

A dedicated venv at **`/opt/audio-tools-venv`** has `numpy`, `scipy`, `soundfile`,
`matplotlib`, and `librosa` (system `libsndfile1` + `ffmpeg` are installed). Use it to
inspect engine output — peak/RMS/dBFS, FFT/STFT, onset detection, pitch tracking, and
spectrogram images:

```bash
/opt/audio-tools-venv/bin/python your_analysis.py render.wav
```

The engine exposes `EngineHost::renderOffline(lengthBeats, sampleRate)` (mono float, see
`engine_juce/include/audioapp/EngineHost.hpp`); dump that to a WAV and analyze it. Note
that the simple oscillator is harmonically rich, so naive per-window `argmax` pitch
detection is unreliable — prefer a spectrogram or `librosa.pyin`/onset detection.
