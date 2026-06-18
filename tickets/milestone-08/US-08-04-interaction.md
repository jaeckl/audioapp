# US-08-04-interaction: Parameter automation — Interaction

## Type

Interaction

## Parent feature

[US-08-04](US-08-04-parameter-automation.md)

## Entry points

- Parameter menu → Automate
- Long-press device knob → Automate this
- Library → Automation templates
- Automation clip Link chip

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Add breakpoint | Tap lane / double-tap clip | Dot appears | Write automation |
| Move breakpoint | Drag in curve editor | Value changes | Update |
| Automate param | Long-press knob | Snackbar + clip | Create linked clip |
| Link target | Link chip → tap knob | Purple pulse | Assign device param |
| Play | Transport | Hear sweep | Evaluate automation |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Delete breakpoint tap

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Automate filter cutoff → Play sweep

## Acceptance criteria

- [x] Save/load restores breakpoints
- [x] Link Mode assigns parameter from device strip

## Status

**Done**
