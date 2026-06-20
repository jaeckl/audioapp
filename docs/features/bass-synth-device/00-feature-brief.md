# Feature Brief: Bass Synth Device

## User-visible goal

Add a dedicated **Bass Synth** instrument device optimized for fast, focused bass sound design on mobile. The user picks "Bass Synth" from the device picker, sees a compact mobile-optimized UI with 16 curated knobs organized in three sections (TONE, FILTER, CHARACTER), tweaks parameters, and plays grungy/sub/dark/analog/screaming basses immediately. The device defaults to mono legato with an always-on sub-oscillator, pre-wired filter envelope, key-track, and light unison — no setup required.

## Non-goals

- Do not create a new audio DSP engine. Reuse `SubtractiveSynth` entirely.
- Do not expose SubtractiveSynth's ~50 parameters. Curate exactly 16.
- Do not add a built-in compressor DSP node (squash uses feedback compression in SubtractiveSynth).
- Do not add preset management (future feature).
- Do not touch the SubtractiveSynth test files or modify its runtime behavior.

## Demo script (PO acceptance)

1. User opens device picker → sees "Bass Synth" entry
2. Taps "Bass Synth" → device appears in chain with header showing "Bass Synth · Mono · Sub"
3. Card shows three tabs: TONE, FILTER, CHAR
4. User tweaks oscShape knob → sound morphs
5. User tweaks subMix → sub bass level changes
6. User plays MIDI notes → mono legato glide on overlapping notes
7. User saves project → reload → all bass parameters restored
8. User records automation on filterCutoff → plays back correctly

## Existing code to reuse

- `SubtractiveSynth` full engine (oscillators, filter, envelopes, unison, drive, feedback)
- `SubtractiveSynthParams` as the audio-thread param snapshot
- `mixSubtractiveMidiNotesBlock` / `renderSubtractiveLiveVoice` for playback
- `SubtractiveSynthRuntime` / `SubtractiveVoiceRuntime` for voice state
- `DeviceRegistry` registration pattern
- `IDeviceType` interface
- `DeviceSlot` variant pattern
- `DeviceNodePlayback` / `DeviceVariantParams` dispatch pattern
- Flutter `DeviceStripSlot` / `DeviceStripMetrics` / `DeviceStripTheme` routing