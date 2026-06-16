# Testing Guidelines

## Layers

| Layer | Tool | Location |
|-------|------|----------|
| C++ unit | CMake + test framework | `engine_juce/tests/` |
| C++ golden render | Offline bounce + compare | `engine_juce/tests/` |
| Flutter widget | `flutter test` | `app_flutter/test/` |
| Flutter integration | `integration_test` | `app_flutter/integration_test/` |
| Bridge | Dart + native smoke | both |
| Android smoke | Manual / CI APK build | `tools/build_android.sh` |

## Requirements per milestone

Every milestone ticket lists required test types. Audio milestones require at least one non-listening verification (golden or signal property test).

## Golden tests

- Fixed sample rate, block size, and MIDI input
- Compare RMS, peak, or sample hash against reference
- Store references in `fixtures/`

## CI (future)

- `tools/test_all.sh` orchestrates available suites
- Android APK debug build on main branch
