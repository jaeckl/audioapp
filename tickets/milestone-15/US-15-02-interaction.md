# US-15-02-interaction: Kick bench layout + kickModel engine branch — Interaction

## Type

Interaction

## Parent feature

[US-15-02](US-15-02-kick-bench-kick-model.md)

## Entry points

- Insert Kick Generator → expand slot

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Tweak Pitch | Drag knob | Preview pitch curve updates | Deeper/higher kick |
| Raise Click | Drag knob | Transient preview | Sharper attack |
| Select 808 | Tap segment | 808 highlighted | kickModel=0 |
| Save project | Save | Layout unchanged on reload | Round-trip |

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

Remove device — bench dismissed

## Error paths

_None beyond parent feature._

## Demo script (interaction-only)

- All knobs visible → tweak punch/decay → save/reload

## Acceptance criteria

- [ ] kickModel in JSON; hear timbre change on timeline


## Status

**Todo**
