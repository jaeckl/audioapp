# US-01-01: Play hears JUCE audio

## Type

Feature

## Milestone

Milestone 01 — First real sound

## User story

As a **user**, I press Play and hear real sound from the JUCE engine on my Android device, and Stop silences it.

## Goal

Complete vertical path: Flutter → MethodChannel → C++ engine → Android audio output.

## Background

- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)
- [flutter_native_bridge.md](../../docs/bridge/flutter_native_bridge.md)
- [juce_dependency.md](../../docs/architecture/juce_dependency.md)

## Scope

- Wire `play` / `stop` bridge commands to JUCE audio device
- `TestOscillator` (or click) on audio callback
- Gradle/CMake link `engine_juce` + `native_bridge` into Android app
- Throttled transport events to Flutter (optional, minimal)

## Out of scope

- Project model, tracks, MIDI clips
- Save/load

## Acceptance criteria

- [ ] Play produces audible tone on physical device
- [ ] Stop silences output
- [ ] No Flutter/JNI/platform calls from audio thread
- [ ] C++ offline test: oscillator output non-silent (RMS > threshold)
- [ ] Flutter test: play/stop commands dispatched
- [ ] Bridge doc lists final command names and thread rules

## Tests required

- [ ] `engine_juce/tests/` golden or RMS test
- [ ] Flutter widget/unit test for play/stop
- [ ] Manual smoke on Moto / device

## User-visible result

User opens app, taps Play, hears real JUCE-generated sound.

## Realtime/performance notes

- Zero allocations in `processBlock`
- Review against realtime checklist

## Documentation updates

- [ ] `docs/bridge/flutter_native_bridge.md`
- [ ] `docs/milestones/milestone-01.md`

## Depends on

US-00-01, US-00-02

## Status

**Todo** — next milestone
