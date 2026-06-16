# US-04-02-interaction: Add and delete notes — Interaction

## Type

Interaction

## Parent feature

[US-04-02](US-04-02-add-delete-notes.md)

## Entry points

- Piano roll open

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Add note | Tap empty cell | Block appears | setMidiClipNotes |
| Delete note | Tap note | Block removed | setMidiClipNotes |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

N/A

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Add 4 notes → delete 1 → Play

## Acceptance criteria

- [x] Snap visible on add


## Status

**Done**
