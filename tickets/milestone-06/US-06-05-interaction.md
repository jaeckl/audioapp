# US-06-05-interaction: Playhead sample audition — Interaction

## Type

Interaction

## Parent feature

[US-06-05](US-06-05-playhead-sample-audition.md)

## Entry points

- Play transport with sample clips on selected track

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Play through clip | Play | Sample audible | Schedule by playhead |
| Stop | Stop | Silence | Stop voices |
| Select other track | Track tap | Audition follows selection | selectedTrackId |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Stop

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Decode fail | Toast on play | No crash |

## Demo script (interaction-only)

- Kick bar1 snare bar2 → Play → hear sequence

## Acceptance criteria

- [ ] Hear each clip as playhead enters


## Status

**Todo**
