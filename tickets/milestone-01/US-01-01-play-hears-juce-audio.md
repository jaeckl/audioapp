# US-01-01: Play hears engine audio

## Type

Feature

## Milestone

Milestone 01 — First real sound

## User story

As a **user**, I press Play and hear real sound from the native engine on my Android device, and Stop silences it.

## Goal

Complete vertical path: Flutter → MethodChannel → C++ engine → Android audio output.

## Background

- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)
- [flutter_native_bridge.md](../../docs/bridge/flutter_native_bridge.md)
- [juce_dependency.md](../../docs/architecture/juce_dependency.md)

## Scope

- Wire `play` / `stop` bridge commands to native audio (AAudio on Android)
- `TestOscillator` on audio callback
- Gradle/CMake link `engine_juce` + `native_bridge` into Android app

## Out of scope

- Project model, tracks, MIDI clips
- Save/load
- Full JUCE CMake on Android (tracked separately — see juce_dependency.md)

## Acceptance criteria

- [x] Play produces audible tone on physical device
- [x] Stop silences output
- [x] No Flutter/JNI/platform calls from audio callback
- [x] C++ offline test: oscillator output non-silent (RMS > threshold)
- [x] Flutter test: play/stop commands dispatched
- [x] Bridge doc lists final command names and thread rules

## Tests required

- [x] `engine_juce/tests/oscillator_output_test.cpp`
- [x] Flutter `engine_bridge_test.dart`
- [x] Manual smoke on Moto / device

## User-visible result

User opens app, taps Play, hears a 440 Hz test tone.

## Demo script (on-device, ~20s)

1. Open app → Play → hear tone → Stop → silence.

## Realtime/performance notes

- Stack buffer only in AAudio callback; no heap alloc in RT path

## Documentation updates

- [x] `docs/bridge/flutter_native_bridge.md`
- [x] `docs/architecture/juce_dependency.md`

## Depends on

US-00-01, US-00-02

## Status

**Done**
