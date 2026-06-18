# US-15-04-interaction: Dynamics input and output panels — Interaction

## Type

Interaction

## Parent feature

[US-15-04](US-15-04-dynamics-input-output-panels.md)

## Entry points

- Insert gate/compressor/expander/limiter → expand

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Play loop | Transport | Input meter moves | Signal visible pre-FX |
| Lower threshold | Drag on card | GR increases on hits | Compression audible |
| Trim output Gain | Drag output Gain | Level post-FX changes | Make-up gain |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Collapse slot

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Kick → compressor → threshold down → GR moves → output Gain trim

## Acceptance criteria

- [ ] Slot width includes input + output for dynamics


## Status

**Todo**
