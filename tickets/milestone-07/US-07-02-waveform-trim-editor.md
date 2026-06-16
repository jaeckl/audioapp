# US-07-02: Waveform trim editor

## Type

Feature

## Milestone

Milestone 07 — Sampler fullscreen editor

## User story

As a **user**, I can see a **waveform** and set **trim start/end** with handles so playback uses only the slice I want — without changing the file on disk.

## Goal

M07 **wow moment:** visual waveform + trim handles + audible result. PO: **waveform required**.

## Background

- AGENT.md §2.8 investor-quality mobile UX

## UX flow

1. Open fullscreen sampler (US-07-01).
2. **Waveform** displays full sample (static image/path OK for v1; no pinch-zoom required).
3. Drag **start** and **end** handles on waveform.
4. Tap **Preview** → hears trimmed region.
5. Return to arrangement → Play MIDI clip → trim respected.
6. Original imported/bundled file unchanged on disk.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Handles large enough for thumb; preview button reachable |

## Scope

- Waveform render (engine peak cache or Flutter canvas from decoded peaks)
- Trim `startSec` / `endSec` in device parameters
- Preview playback on control thread
- Sampler RT reads trim bounds
- `project.json` serialization via juce::JSON

## Out of scope

- Destructive bounce/export of trimmed audio
- Time-stretch, pitch-shift
- Multi-sample zones

## Acceptance criteria

- [ ] Waveform visible for assigned sample
- [ ] Trim handles adjust start/end
- [ ] Preview plays trimmed region only
- [ ] MIDI playback uses trim bounds
- [ ] Save/load restores trim
- [ ] Source file byte-identical after session
- [ ] C++ tests trim metadata round-trip

## Demo script (on-device, ~60s)

1. Open long sample → trim to short hit → Preview → hear chop.
2. Play clip in arrangement → same chop → Save/Load → still trimmed.

## Tests required

- [ ] C++ playback with trim bounds
- [ ] Serialization tests
- [ ] Flutter widget tests for handles
- [ ] Manual on device

## User-visible result

**Wow:** shape samples visually on phone like a mini DAW editor.

## Depends on

US-07-01, US-06-04

## Status

**Todo**
