# US-06-04-interaction: MIDI triggers sample — Interaction

## Type

Interaction

## Parent feature

[US-06-04](US-06-04-midi-triggers-sample.md)

## Entry points

- Play with sampler + MIDI clip

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Trigger | Play | Sample voices | MIDI→sampler |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Stop

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| No sample | Error on play attempt | Silent fail NOT OK |

## Demo script (interaction-only)

- 4-on-floor → Save → Load → Play

## Acceptance criteria

- [ ] Round-trip on device


## Status

**Todo**
