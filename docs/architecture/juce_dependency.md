# JUCE Dependency Strategy

## Decision

JUCE is integrated via **CMake FetchContent** with a **pinned Git tag**.

## Pinned version

| Property | Value |
|----------|-------|
| Repository | `https://github.com/juce-framework/JUCE.git` |
| Tag | `8.0.4` |
| Declared in | `engine_juce/CMakeLists.txt` |

## Rationale

- Reproducible builds without vendoring a full JUCE tree in git
- Works in dev container and CI without manual install steps
- Submodule alternative remains possible if FetchContent causes issues

## Build

### Linux (dev container / CI)

```bash
cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
cmake --build build/engine
```

### Windows (local dev)

Requires **Visual Studio 2022 Build Tools** (MSVC x64 + Windows SDK) and **Ninja**:

```powershell
# Activate MSVC environment, then:
cmake -S engine_juce -B build/engine -G Ninja
cmake --build build/engine
```

First configure downloads JUCE into the CMake build directory.

> **MinGW is not supported.** JUCE 8 requires C++20 designated initializers and MSVC-specific features. Use MSVC (VS 2022 Build Tools) on Windows.

## Modules used (initial)

- `juce_audio_basics`
- `juce_audio_devices`
- `juce_audio_processors`
- `juce_core` — includes **`juce::JSON`**, `juce::var`, file utilities
- `juce_events`

## JSON / project files

Project serialization (`project.json` inside `.audioapp.zip`) must use **`juce::JSON`** on the control thread:

- Parse: `juce::JSON::parse(jsonString)` → `juce::var`
- Emit: `juce::JSON::toString(var, true)` for pretty, diffable output
- Build objects with `juce::DynamicObject` or `juce::var` property trees

Do not maintain a parallel custom JSON parser in `engine_juce`. Legacy hand-rolled code should be migrated when touching serialization.

Realtime rule unchanged: no JSON work on the audio callback.

### Android engine

The Android `.so` links **`juce_core`** (`JUCE_MODULES_ONLY`) for `juce::JSON` on the control thread. Audio still uses AAudio (`EngineHost_android.cpp`). CMake projects must enable **`LANGUAGES CXX C`** when linking JUCE modules.

## Android vs desktop

| Platform | Audio backend | Notes |
|----------|---------------|-------|
| **Android (M01)** | AAudio via `EngineHost_android.cpp` | Same `TestOscillator` DSP; no JUCE CMake on device (avoids `juceaide` cross-compile) |
| **Desktop / host tests** | JUCE `AudioDeviceManager` via `EngineHost_juce.cpp` | FetchContent JUCE 8.0.4 |

Full JUCE-on-Android CMake linking is available now — `juceaide` bootstraps automatically with **MSVC** (VS 2022 Build Tools) on Windows or **GCC** on Linux.

## Updating JUCE

1. Change the tag in `engine_juce/CMakeLists.txt`
2. Rebuild and run engine tests
3. Update this document and add an ADR note if the bump is significant

## Manual override (local dev)

Set `JUCE_PATH` to a local JUCE checkout and adjust CMake if FetchContent must be skipped (document any local overrides; do not commit machine-specific paths).
