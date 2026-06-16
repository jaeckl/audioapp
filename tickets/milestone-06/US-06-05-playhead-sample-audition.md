# US-06-05: Playhead sample audition

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, when a **track is selected**, I want to **hear the sample** when the **playhead moves across** a sample clip — during playback or when scrubbing — so I can preview the arrangement in context.

## Goal

M06 **wow moment:** moving playhead through sample clips on the **selected track** triggers audible sample playback (clip region aware).

## Background

- Extends US-03-02 playhead with **audio clip** scheduling
- PO: "track cursor moves by it" — playhead crossing clip triggers sound
- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)

## UX flow

1. User selects track with sample clip(s).
2. User presses **Play** → as playhead enters each sample clip region, sample plays (from clip start offset by playhead position within clip).
3. **Optional MVP+:** while stopped, dragging/scrubbing playhead across clip auditions snippet (document if deferred).
4. User selects different track → audition follows **selected track only** (other tracks' sample clips silent unless playing full mix later).
5. Stop → silence.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | No underruns on simple 2-clip project; latency acceptable for demo |

## Scope

- C++ audio clip scheduler: given `playheadBeat`, `selectedTrackId`, emit sample segment for active clip
- One-shot or windowed read from decoded sample buffer (trim-aware hook for M07)
- Flutter: no extra UI beyond playhead + selection (US-03-02)
- Only **selected track** sample clips audition in this story (document)

## Out of scope

- Full mix of all tracks' audio clips simultaneously (later)
- MIDI + sample simultaneous mix polish (best-effort OK)
- Sampler device / MIDI triggers (deferred)

## Acceptance criteria

- [ ] Play: hear sample when playhead traverses clip on **selected** track
- [ ] Stop: immediate silence
- [ ] Multiple clips on track: each triggers at correct beat
- [ ] Unselected track: sample clips not heard during this audition mode (or document mix behavior)
- [ ] C++ scheduling tests with known playhead positions
- [ ] Manual demo on device

## Demo script (on-device, ~60s)

1. Insert kick clip at bar 1, snare at bar 2 → select track → Play → hear kick then snare as playhead passes.
2. Save → Load → repeat.

## Tests required

- [ ] C++ playhead + sample clip scheduling tests
- [ ] Manual on device

## User-visible result

**Wow:** the timeline **plays** your samples as the cursor moves — musical and intuitive.

## Realtime/performance notes

Pre-decoded buffers; no file I/O on audio thread; voice pool for overlapping clips if needed.

## Depends on

US-06-03, US-06-04, US-03-02

## Companion stories

- [UX/UI](US-06-05-ux-ui.md)
- [Interaction](US-06-05-interaction.md)

## Status

**Todo**
