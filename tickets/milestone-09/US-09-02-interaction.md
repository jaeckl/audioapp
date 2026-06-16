# US-09-02-interaction: Export WAV — Interaction

## Type

Interaction

## Parent feature

[US-09-02](US-09-02-export-wav-system-dialog.md)

## Entry points

- Export button

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Export | Tap | Render offline | Progress updates |
| Save file | SAF CreateDocument | WAV written | Success |
| Cancel dialog | Back | No file | Render may cancel |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Dialog cancel after render discards or saves to cache — document

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Disk full | Error message | No corrupt WAV |

## Demo script (interaction-only)

- Export → save mybeat.wav → open externally

## Acceptance criteria

- [ ] Default .wav name
- [ ] MIME audio/wav

## Status

**Todo**
