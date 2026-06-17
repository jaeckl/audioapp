# US-03-02-interaction: Transport playhead — Interaction

## Type

Interaction

## Parent feature

[US-03-02](US-03-02-transport-playhead.md)

## Entry points

- Play transport

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Play | Transport | Playhead moves | advancePlayhead |
| Stop | Transport | Playhead stops | playing false |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Stop freezes position

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Play 4 beats → watch playhead → Stop

## Acceptance criteria

- [x] Smooth enough at 120 BPM


## Status

**Done**
