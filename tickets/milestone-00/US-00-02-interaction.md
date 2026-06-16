# US-00-02-interaction: DAW shell placeholder — Interaction

## Type

Interaction

## Parent feature

[US-00-02](US-00-02-daw-shell-placeholder.md)

## Entry points

- App launch

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Open app | Launcher icon | Splash → shell | Shell visible |
| Select placeholder track | Track row tap | Highlight | Device strip shows |
| Ping bridge | Automatic on load | Status shows connected | pong in status |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

N/A — no destructive flows

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Bridge fail | Red status / error text | Shell still usable |

## Demo script (interaction-only)

- Launch → see three regions → tap track → strip appears

## Acceptance criteria

- [x] Cold start < 3s to shell
- [x] Track tap responsive

## Status

**Done**
