# US-06-03-interaction: Insert sample clip on track — Interaction

## Type

Interaction

## Parent feature

[US-06-03](US-06-03-insert-sample-clip-on-track.md)

## Entry points

- Sample library with track selected

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Insert | Insert on track | Clip on timeline | createSampleClip |
| Wrong track | Select track first | Toast if none | No orphan clip |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Back from library without insert

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| No track selected | Toast | No clip created |

## Demo script (interaction-only)

- Select track → library → insert kick → clip appears

## Acceptance criteria

- [ ] ≤3 taps from library to clip visible


## Status

**Todo**
