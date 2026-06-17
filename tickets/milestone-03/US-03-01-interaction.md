# US-03-01-interaction: Create MIDI clip — Interaction

## Type

Interaction

## Parent feature

[US-03-01](US-03-01-create-midi-clip-on-timeline.md)

## Entry points

- Timeline with track selected

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Create clip | Add clip control | Block appears | createMidiClip |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

N/A

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| No track selected | Disabled or toast | No orphan clip |

## Demo script (interaction-only)

- Select track → add clip → block on bar 1

## Acceptance criteria

- [x] Clip tappable for editor (M04)


## Status

**Done**
