# US-15-03-interaction: Mono drum output panels — Interaction

## Type

Interaction

## Parent feature

[US-15-03](US-15-03-mono-drum-output-panels.md)

## Entry points

- Expand kick/snare/clap/cymbal slot

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Lower Gain | Drag Gain | Quieter hits | gain param updated |
| Vel sens 0% | Drag Vel sens | Pads same level | Velocity ignored |
| Vel sens 100% | Drag Vel sens | Harder pad = louder | Velocity scales hit |
| Save | Save project | Gain + Vel sens restored | Round-trip |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Collapse slot

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Kick Gain 50% → Vel sens sweep on pads → save/reload

## Acceptance criteria

- [ ] All four drum types share DrumMonoOutputPanel layout


## Status

**Todo**
