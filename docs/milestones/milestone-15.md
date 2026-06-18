# Milestone 15 — Device strip UX chrome

**ADR:** [ADR-0008](../adr/ADR-0008-device-strip-ui-chrome.md)  
**Design:** [device_strip_chrome.md](../design/device_strip_chrome.md)

## Theme

Per-device **input** and **output** strip columns; kick **bench** single-page layout; `kickModel` DSP branching without new device types.

## Stories

| ID | Title | Depends on |
|----|-------|------------|
| US-15-01 | Device strip chrome framework | — |
| US-15-02 | Kick bench + `kickModel` engine branch | US-15-01 |
| US-15-03 | Mono drum output panels | US-15-01 |
| US-15-04 | Dynamics input + output panels | US-15-01 |
| US-15-20 | M15 PO demo — strip chrome on device | US-15-02 … 04 |

## Demo script (US-15-20, ~60s)

1. Kick on track — one-page bench, Gain + Vel sens on right rail, no Pan.
2. Insert compressor — input meter column left of card, GR on right.
3. Save/reload — chrome layout and params intact.

## Supersedes

- M13 “shared 3-tab drum strip” for **kick** (see [kick_generator_ux_addendum.md](../design/drum_generators/kick_generator_ux_addendum.md)).
- Universal `DeviceLevelPanel` for all device types.
