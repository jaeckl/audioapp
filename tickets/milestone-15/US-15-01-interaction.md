# US-15-01-interaction: Device strip chrome framework — Interaction

## Type

Interaction

## Parent feature

[US-15-01](US-15-01-device-strip-chrome-framework.md)

## Entry points

- Expand device in chain

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Expand synth | Tap slot | Pan + Gain on right | Stereo output rail |
| Expand compressor | Tap slot | Input column + GR output | Dynamics chrome |
| Toggle mod strip | Mod button | Input/output stay aligned | Chrome stable |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Collapse slot — chrome hidden with card

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Synth vs compressor — different strip columns visible

## Acceptance criteria

- [ ] Registry returns correct panels per device type


## Status

**Todo**
