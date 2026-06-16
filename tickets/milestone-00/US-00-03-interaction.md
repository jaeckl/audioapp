# US-00-03-interaction: Edge-to-edge shell layout — Interaction

## Type

Interaction

## Parent feature

[US-00-03](US-00-03-edge-to-edge-shell-layout.md)

## Entry points

- Rotate device
- Gesture nav

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Rotate portrait ↔ landscape | Device rotation | Reflow | Full bleed maintained |
| Navigate home gesture | System gesture | App backgrounds | State preserved on return |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

N/A

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Portrait full bleed → rotate landscape → cutout acceptable → transport still works

## Acceptance criteria

- [x] Manual on physical device both orientations


## Status

**Done**
