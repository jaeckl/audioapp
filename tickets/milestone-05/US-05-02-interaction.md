# US-05-02-interaction: Load project — Interaction

## Type

Interaction

## Parent feature

[US-05-02](US-05-02-load-project.md)

## Entry points

- Load toolbar button

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Load | Load tap | SAF OpenDocument | Parse + snapshot |
| Cancel | Dialog cancel | Silent | Prior state |
| Success | Pick zip | UI refresh + Loaded project | Engine loaded |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Silent on cancel

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Bad zip | Red error | Prior state kept |
| Empty parse bug | MUST NOT happen — treat as error | Prior state kept |

## Demo script (interaction-only)

- Save → kill app → Load → tracks back

## Acceptance criteria

- [x] Round-trip on device


## Status

**Done**
