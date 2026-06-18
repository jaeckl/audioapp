# US-08-19: Parameter automation playback on transport

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **producer**, when I press **Play**, automation clips on the timeline **modulate device parameters** in sync with the transport playhead.

## Goal

Realtime-safe playback path: evaluate envelopes at block rate and apply absolute parameter values before device DSP.

## Scope

- `evaluateAutomationEnvelope` linear interpolation
- `applyAutomationValue` for sampler/synth/oscillator params (gain, pan, filterCutoff, ADSR, frequency)
- Mix integration in `processDeviceChain` per track
- `renderOffline` uses same path

## Acceptance criteria

- [x] Filter cutoff sweep audible in offline render test
- [x] Automation only active when playhead inside clip span
- [x] Linked clip required (`deviceId` + `paramId` + points)
- [ ] Manual on-device verification

## Tests required

- [x] `engine_juce/tests/automation_clip_test.cpp` (renderOffline peak)
- [ ] Golden WAV comparison (optional)

## Depends on

US-08-04-parameter-automation

## Status

**Done**
