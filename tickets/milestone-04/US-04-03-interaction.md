# US-04-03-interaction: Move and resize notes — Interaction

## Type

Interaction

## Parent feature

[US-04-03](US-04-03-move-resize-notes-grid-snap.md)

## Entry points

- Note in piano roll

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Move | Drag note body | Follows finger; snap on release | setMidiClipNotes |
| Resize | Drag end handle | Length changes | setMidiClipNotes |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Release commits; no revert gesture in MVP

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Move note up → lengthen → Play

## Acceptance criteria

- [x] One command per gesture end, not per pixel


## Status

**Done**
