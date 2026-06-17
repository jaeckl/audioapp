# US-01-01-interaction: Play hears engine audio — Interaction

## Type

Interaction

## Parent feature

[US-01-01](US-01-01-play-hears-juce-audio.md)

## Entry points

- Transport bar

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Start audio | Play button | Icon → Stop; optional status | Tone audible |
| Stop audio | Stop button | Icon → Play | Silence immediate |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Stop always available while playing

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Audio init fail | Error in status area | No fake playing state |

## Demo script (interaction-only)

- Play → hear tone → Stop → silence

## Acceptance criteria

- [x] < 200ms perceived start
- [x] Stop immediate

## Status

**Done**
