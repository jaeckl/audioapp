# US-04-11-interaction: Piano roll clip bounds & end marker — Interaction

## Type

Interaction

## Parent feature

[US-04-11](US-04-11-piano-roll-horizontal-scroll-and-clip-bounds.md)

## Entry points

- Piano roll open on MIDI clip

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Resize clip | Drag end pill | Red line moves; release persists | setClipLength |
| Edit past end | Draw note right of line | Note appears | setMidiClipNotes |
| Play shortened | Play transport | Notes past boundary silent | engine gate |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Drag away without release still commits on pointer up

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| setClipLength fail | SnackBar + save error state | Boundary reverts on reload |

## Demo script (interaction-only)

- Shorten to 2 bars → play → lengthen → play again

## Acceptance criteria

- [x] One setClipLength per drag release
- [x] 28px hit target on marker

## Status

**Done**
