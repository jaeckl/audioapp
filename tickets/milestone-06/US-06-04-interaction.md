# US-06-04-interaction: Waveform in arrangement — Interaction

## Type

Interaction

## Parent feature

[US-06-04](US-06-04-waveform-in-arrangement.md)

## Entry points

- View arrangement after insert

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Scroll timeline | Horizontal scroll | Waveform scrolls with clip | Cached peaks |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

N/A

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Missing peaks | Flat fallback | Clip still visible |

## Demo script (interaction-only)

- Two clips → different shapes

## Acceptance criteria

- [ ] No jank scrolling 2+ clips


## Status

**Todo**
