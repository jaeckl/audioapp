# US-04-11: Piano roll clip bounds & draggable end marker

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can **see where my MIDI clip ends** on the piano roll and **drag the end marker** to change playback length, while still **editing notes past the boundary** if I need to.

## Goal

Clip `lengthBeats` is the audible window; the red boundary line and draggable handle make that window obvious and editable from the piano roll.

## Background

- `lengthBeats` already exists on MIDI/sample clips in the engine snapshot.
- Notes may extend past the clip end in storage; playback must gate at the span.
- Future clip kinds (automation, audio) share the same timeline span model.

## Architecture

### Shared clip span (C++ + Dart)

| Layer | Type | Fields |
|-------|------|--------|
| C++ | `ClipTimelineSpan` / `ClipContentKind` | `id`, `startBeat`, `lengthBeats`, `kind` |
| Dart | `ClipTimelineSpan` | same + `endBeat` getter |
| MIDI | `MidiClipSnapshot` | span + `notes` |
| Sample | `SampleClipSnapshot` | span + `sampleId`, peaks |

`setClipLength(clipId, lengthBeats)` is content-agnostic — works for MIDI and sample clips.

### Playback gating

- `DeviceChain`: note end = `min(noteStart + duration, clipLengthBeats)` inside the clip loop.
- Notes with `startBeat >= lengthBeats` are silent.
- Notes straddling the boundary are truncated at play time.

### Piano roll UX

- **Red vertical line** at `clipLengthBeats` (grid painter + marker overlay).
- **Pill handle** anchored on the ruler row atop the line (~28px hit target).
- **Virtual grid** (`virtualLengthBeats`) ≥ clip length + padding — horizontal scroll exposes bars beyond the clip; notes can be placed past the line.
- Drag end marker → live preview → `setClipLength` on pointer up.

## UX flow

1. Open piano roll on a 4-bar clip.
2. See red boundary at bar 4 with pill handle on ruler.
3. Drag handle left to 2 bars → boundary moves; notes past beat 2 remain visible but muted on Play.
4. Draw a note at beat 3 (past shortened boundary) → note saves; still silent until clip lengthened.
5. Close piano roll → arrangement clip width reflects new length.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | End-marker drag locks horizontal scroll; handle ≥ 28dp wide |

## Scope

- `TimelineClipTypes.hpp`, `timeline_clip.dart`, `clip_snapshots.dart`
- `ProjectEngine::setClipLength`, bridge, `EngineBridge.setClipLength`
- `PianoRollClipEndMarker`, viewport hit-test + drag
- C++ `clip_length_test.cpp`, Flutter bridge test

## Out of scope

- Arrangement-view clip resize (US-04-15)
- Clip start marker / slip editing
- Automation lanes

## Acceptance criteria

- [x] Red clip boundary visible in piano roll grid
- [x] Draggable end marker on ruler atop boundary line
- [x] `setClipLength` persists via bridge; snapshot `lengthBeats` updates
- [x] Notes past boundary remain editable and stored
- [x] Playback truncates / mutes notes beyond `lengthBeats`
- [x] C++ + Flutter tests for length change round-trip

## Demo script (on-device, ~60s)

1. Open piano roll → add long note spanning beats 0–3.
2. Drag end marker to beat 2 → Play → note cuts off at beat 2.
3. Draw note at beat 3 → Play → silent.
4. Drag marker to beat 4 → Play → note at 3 audible.

## Tests required

- [x] `clip_length_test.cpp` — setClipLength, serialization, playback gate
- [x] `engine_bridge_test.dart` — setClipLength mock round-trip
- [x] Manual on device

## User-visible result

**Wow:** shorten a loop region in the piano roll and hear it tighten immediately — without losing notes you parked past the edge.

## Depends on

US-04-05, US-04-03

## Companion stories

- [UX/UI](US-04-11-ux-ui.md)
- [Interaction](US-04-11-interaction.md)

## Status

Done
