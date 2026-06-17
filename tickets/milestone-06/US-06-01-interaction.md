# US-06-01-interaction: Bundled sample library — Interaction

## Type

Interaction

## Parent feature

[US-06-01](US-06-01-bundled-sample-library.md)

## Entry points

- Library button from shell or strip

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Open library | Menu/button | Navigate | List loads |
| Preview | Row tap or preview btn | Audio audition | Short play |
| Insert on track | Button on row | Returns to arrangement | US-06-03 when wired |
| Close | Back | Return | Stop preview |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Back stops preview

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Preview fail | Toast | List still usable |

## Demo script (interaction-only)

- Open → preview kick → preview snare

## Acceptance criteria

- [ ] Preview < 2s start


## Status

**Todo**
