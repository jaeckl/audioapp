# US-11-05-ux-ui: Osc tab + waveform previews — UX & UI

## Type

UX / UI

## Parent feature

[US-11-05](US-11-05-osc-tab-waveform-previews.md)

## Design intent

Waveform previews mirror **sampler strip polish** — antialiased curves on dark background, selected wave highlighted.

## Layout & hierarchy

- Two preview panels (osc1 / osc2) stacked or side-by-side in landscape
- Wave icon row under each preview

## Visual states

| State | Treatment |
|-------|-----------|
| Selected wave | Accent border + filled icon |
| Pulse | Optional width slider if pulse wave selected |

## Acceptance criteria (visual)

- [ ] Previews match selected wave shape (golden painter test)
- [ ] Tab height within device strip cardChromeHeight budget

## Status

**Todo**
