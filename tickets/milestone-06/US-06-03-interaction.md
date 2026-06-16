# US-06-03-interaction: Sampler on device strip — Interaction

## Type

Interaction

## Parent feature

[US-06-03](US-06-03-sampler-device-on-strip.md)

## Entry points

- Add sampler to strip
- Choose sample

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Add sampler | Add device | Card appears | addDeviceToTrack |
| Choose | Button | Library picker | Assign sample ID |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Picker cancel → no change

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Missing sample on play | Documented toast | No crash |

## Demo script (interaction-only)

- Add sampler → choose kick → name on card

## Acceptance criteria

- [ ] Return from library preserves strip context


## Status

**Todo**
