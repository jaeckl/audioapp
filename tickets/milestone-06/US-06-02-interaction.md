# US-06-02-interaction: Import sample — Interaction

## Type

Interaction

## Parent feature

[US-06-02](US-06-02-import-sample-system-picker.md)

## Entry points

- Library → Import

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Import | Import tap | SAF OpenDocument | Register sample |
| Cancel | Dialog cancel | Silent | List unchanged |
| Success | Pick audio | Row in Imported | Stable ID |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Silent

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Unsupported | Error message | No partial row |

## Demo script (interaction-only)

- Import WAV → appears → preview

## Acceptance criteria

- [ ] MIME filter + */* fallback


## Status

**Todo**
