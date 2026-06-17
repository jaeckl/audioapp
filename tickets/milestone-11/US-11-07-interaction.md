# US-11-07-interaction: Fullscreen synth editor — Interaction

## Type

Interaction

## Parent feature

[US-11-07](US-11-07-fullscreen-synth-editor-test-note.md)

## Entry points

- Strip expand / fullscreen affordance

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Open fullscreen | Expand icon | Route push | editor screen |
| Hold test note | Button | C4 audible | noteOn while down |
| Release test note | Button up | Silence | noteOff |
| Back | System back / chevron | Pop route | strip unchanged state |

## Cancel & back

- Back does not discard unsaved params (live params already in engine)

## Demo script (interaction-only)

- Fullscreen → hold test note → tweak filter → back

## Acceptance criteria

- [ ] Test note works with transport stopped
- [ ] No stuck note on back (allNotesOff or paired noteOff)

## Status

**Todo**
