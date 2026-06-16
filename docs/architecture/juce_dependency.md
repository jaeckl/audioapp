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

```bash
cmake -S engine_juce -B build/engine -G Ninja
cmake --build build/engine
```

First configure downloads JUCE into the CMake build directory.

## Modules used (initial)

- `juce_audio_basics`
- `juce_audio_devices`
- `juce_audio_processors`
- `juce_core`
- `juce_events`

Additional modules added only when needed.

## Android / Flutter integration

The engine builds as a static or shared library linked from the Flutter Android Gradle project via `native_bridge/`. Exact linking is established in Milestone 01.

## Updating JUCE

1. Change the tag in `engine_juce/CMakeLists.txt`
2. Rebuild and run engine tests
3. Update this document and add an ADR note if the bump is significant

## Manual override (local dev)

Set `JUCE_PATH` to a local JUCE checkout and adjust CMake if FetchContent must be skipped (document any local overrides; do not commit machine-specific paths).
