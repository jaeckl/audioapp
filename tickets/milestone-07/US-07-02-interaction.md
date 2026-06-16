# US-07-02-interaction: Waveform trim editor — Interaction

## Type

Interaction

## Parent feature

[US-07-02](US-07-02-waveform-trim-editor.md)

## Entry points

- Fullscreen sampler

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Adjust start | Drag left handle | Region updates | Trim param |
| Adjust end | Drag right handle | Region updates | Trim param |
| Preview | Preview btn | Hear slice | Offline preview |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Back saves trim to engine (auto-commit OK)

## Error paths

| Failure | User sees | Data state |
|---------|-----------|------------|
| Preview fail | Toast | Handles still work |

## Demo script (interaction-only)

- Trim long sample → Preview → Play in arrangement

## Acceptance criteria

- [ ] Handles don't overlap illegally


## Status

**Todo**
