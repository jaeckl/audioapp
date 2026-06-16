# US-03-03-interaction: MIDI clip playback — Interaction

## Type

Interaction

## Parent feature

[US-03-03](US-03-03-midi-clip-playback.md)

## Entry points

- Play with clip on timeline

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Play pattern | Play | Sound + playhead | MIDI schedule |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Stop cuts audio immediately

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Empty clip | Silence or documented | No crash |

## Demo script (interaction-only)

- Clip with notes → Play → hear pattern

## Acceptance criteria

- [x] Loop region repeats if configured


## Status

**Done**
