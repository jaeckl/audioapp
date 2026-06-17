# US-05-01-interaction: Save project — Interaction

## Type

Interaction

## Parent feature

[US-05-01](US-05-01-save-project.md)

## Entry points

- Save toolbar button

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Save | Save tap | SAF CreateDocument | Zip written |
| Cancel dialog | System back | No message | No file |
| Success | Confirm location | Saved project | URI stored |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Dialog cancel → silent return

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| IO fail | Red error text | Project unchanged |

## Demo script (interaction-only)

- Save → pick file → see Saved project

## Acceptance criteria

- [x] Default .audioapp.zip suggested


## Status

**Done**
