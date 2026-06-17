# US-02-03-interaction: Oscillator on device strip — Interaction

## Type

Interaction

## Parent feature

[US-02-03](US-02-03-oscillator-device-strip.md)

## Entry points

- Device strip when track selected

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Change frequency | Slider drag | Hz updates | setDeviceParameter |
| Hear change | Play while adjusting | Pitch changes | Realtime DSP |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Release slider keeps value

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Invalid param | No UI change / error toast | Prior value kept |

## Demo script (interaction-only)

- Slide low → Play → slide high → hear difference

## Acceptance criteria

- [x] Slider does not fight strip scroll


## Status

**Done**
