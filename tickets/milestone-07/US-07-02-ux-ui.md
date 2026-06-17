# US-07-02-ux-ui: Waveform trim editor — UX & UI

## Type

UX / UI

## Parent feature

[US-07-02](US-07-02-waveform-trim-editor.md)

## Design intent

Waveform makes trim trustworthy — PO required visual.

## Layout & hierarchy

Waveform full width; trim handles at start/end; Preview button; time labels.

## Visual states

| State | Treatment |
|-------|-----------|
| Default | Full waveform |
| Trimmed region | Highlighted window |
| Preview | Playing indicator |

## Copy & feedback

- Preview
- Start
- End

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Handles ≥ 48dp touch
- [ ] Waveform readable on AMOLED

## Status

**Todo**
