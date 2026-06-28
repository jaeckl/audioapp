# AGENTS.md

### Rules
DO NOT tell the user how to perform a direct task themselves. Try it on your own first
DO NOT endlessly retry a failing task. You have max 3 tries before you have to think about other solutions

Do the requested task, not a substitute task.

Never claim success unless you verified it with a command result.
Never say "I'll now..." unless the next action is an actual tool command.
Never replace a requested deploy/run/test with "the file is available".
If blocked, say exactly what blocked you and the exact command/user action needed.

For every task:
1. Inspect the current state.
2. Run the required command.
3. Read the result. ( not just return code but also shell output)
4. If it fails, fix or report the concrete blocker.
5. Verify the final state.
6. Only then answer.

Forbidden behavior:
- Do not answer with "you can transfer the APK" when the user asked you to deploy.
- Do not repeat a previous failed answer.
- Do not say "The build was successful" as the final answer unless the task was only to build.
- Do not mark the task done unless the requested target device was reached.

### Headless dev loop (what works here)

| Unit | Command (from repo root) | Notes |
|------|--------------------------|-------|
| Engine build (Linux) | `cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++` then `cmake --build build/engine --target audioapp_engine` | Library builds cleanly; first configure fetches JUCE 8.0.4 over the network. |
| Engine build (Windows) | Activate MSVC (`vcvars64.bat`), then `cmake -S engine_juce -B build/engine -G Ninja` then `cmake --build build/engine --target audioapp_engine` | Requires VS 2022 Build Tools + Windows SDK. MinGW is **not** compatible with JUCE 8. |
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
