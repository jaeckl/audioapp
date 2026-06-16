# US-04-01-interaction: Open piano roll — Interaction

## Type

Interaction

## Parent feature

[US-04-01](US-04-01-open-piano-roll.md)

## Entry points

- Tap clip on timeline

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Open editor | Clip tap | Navigate to roll | Load clip notes |
| Close | Close/back | Return to arrangement | State preserved |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Back returns without save prompt (auto-save via commands)

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- Tap clip → roll → close → timeline

## Acceptance criteria

- [x] System back works


## Status

**Done**
