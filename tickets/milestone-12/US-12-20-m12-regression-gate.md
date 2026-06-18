# US-12-20: M12 regression gate — full engine refactor sign-off

## Type

Test

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **PO/developer**, I want a single regression checklist proving M12 changed architecture without changing user-visible behavior so that we can merge confidently.

## Goal

All automated tests green + documented 60s manual smoke on device confirms playback, parameters, modulation, save/load, and live preview unchanged.

## Background

- M12 is developer-facing but touches every audio path
- US-10-01 was playback-only; M12 touches control model — higher regression risk
- Cloud VM cannot run device emulator — manual section is local PO task

## Scope

- [ ] Run all `engine_juce/tests/*.cpp` individually against `libaudioapp_engine.a`
- [ ] `flutter test` — 51/51
- [ ] `flutter analyze` — 0 errors
- [ ] Document manual smoke script (below) in ticket — PO runs on physical device
- [ ] Update M12 README phase table — mark stories done
- [ ] Close M12 in story manifest

## Manual demo script (~60s, on device)

1. Fresh project → add track → add oscillator → set frequency → **hear tone on play**.
2. Add subtractive synth track → switch device strip tabs → tweak filter → **hear timbre change**.
3. Open modulation → assign LFO to gain → **hear tremolo**.
4. Save project via system dialog → force-stop app → load project → **devices and clips restored**.
5. Play mode → tap pad/key → **live preview audible** → capture → **MIDI clip appears**.

## Acceptance criteria

- [ ] All C++ tests pass (list in Tests required)
- [ ] Flutter 51/51 pass
- [ ] Manual script completed on device (PO sign-off)
- [ ] No P0/P1 bugs filed against M12 scope within 24h of merge

## Tests required

- [ ] `device_chain_test.cpp`
- [ ] `subtractive_synth_test.cpp`
- [ ] `lfo_modulation_test.cpp`
- [ ] `project_serialization_test.cpp`
- [ ] `track_gain_test.cpp`
- [ ] `sample_clip_test.cpp`
- [ ] `device_registry_test.cpp` (from US-12-01)
- [ ] `playback_snapshot_builder_test.cpp` (from US-12-08)
- [ ] Flutter full suite

## Depends on

US-12-11

## Status

Todo
