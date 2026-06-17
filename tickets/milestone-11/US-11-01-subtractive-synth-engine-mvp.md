# US-11-01: Subtractive synth engine MVP (8-voice poly, LP12)

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **developer/PO**, I can render **8-voice polyphonic** subtractive audio from the engine — one saw oscillator per voice, **amp ADSR**, **LP12 filter** with **filter envelope** — so the instrument core is proven before UI polish.

## Goal

Audible, measurable DSP slice in C++ with golden/offline test. No Flutter required for this story's demo (engine test executable or existing offline render hook).

## Background

- [device_model.md](../../docs/architecture/device_model.md)
- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)
- M11 README — **hand-written C++** (not Faust host) for voice pool + serialization integration

## Architecture

- New `DeviceNodeKind::SubtractiveSynth` / `type: "subtractive_synth"`
- Fixed **8-voice** pool with voice stealing (oldest-note or similar — document choice in code)
- Per-voice state: phase, amp env stage, filter env stage, filter `z1/z2` for LP12
- Shared parameters applied via control-thread snapshot (no JSON parse on audio thread)
- **LP12 only** — reuse or extract pattern from sampler multimode filter, expose only low-pass 12 dB/oct
- **No LFO** in this milestone

## Parameter keys (v1, namespaced per device instance)

| Key | Range / enum | Default |
|-----|--------------|---------|
| `osc1_wave` | sine, tri, saw, square, pulse | saw |
| `filter_cutoff` | 20 Hz – 20 kHz (log) | 8 kHz |
| `filter_resonance` | 0 – 1 | 0.2 |
| `filter_env_amount` | 0 – 1 | 0.5 |
| `filter_attack` … `filter_release` | ms | 10 / 200 / 0.6 / 300 |
| `amp_attack` … `amp_release` | ms | 5 / 100 / 0.7 / 200 |

(Osc2, mix, noise, unison added in US-11-03/04.)

## Scope

- `SubtractiveSynthVoice` + `SubtractiveSynthDevice` in `engine_juce/`
- Hook into `processDeviceChain` for `subtractive_synth` nodes
- Note on/off from clip MIDI events **and** live note API (same as sampler)
- Offline/golden test: C4 chord → non-silent buffer, envelope decay measurable

## Out of scope

- Flutter UI (US-11-02+)
- Dual osc, noise, mix modes (US-11-03/04)
- Faust / external DSP codegen
- LFO, mod matrix
- Replacing `simple_oscillator`

## Acceptance criteria

- [ ] 8 simultaneous notes play without crash; 9th steals a voice
- [ ] Amp + filter envelopes shape audible tail
- [ ] LP12 cutoff sweep changes timbre measurably
- [ ] No heap alloc in `processBlock` path
- [ ] C++ golden/offline test passes
- [ ] No NaN/inf in output

## Demo script (engine / test harness, ~30s)

1. Run engine test: trigger 3-note chord → hear saw through LP12 → release → tail decays.

## Tests required

- [ ] C++ golden render test (fixed note list, fixed params)
- [ ] Voice-stealing unit test (9 notes → still 8 active)

## User-visible result

(None yet — engine-only; user hears synth in US-11-02.)

## Depends on

US-08-02, US-10-02

## Companion stories

- [UX/UI](US-11-01-ux-ui.md)
- [Interaction](US-11-01-interaction.md)

## Status

**Todo**
