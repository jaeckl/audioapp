# Milestone 15 — Device strip UX chrome

**ADR:** [ADR-0008](../../docs/adr/ADR-0008-device-strip-ui-chrome.md)  
**Design:** [device_strip_chrome.md](../../docs/design/device_strip_chrome.md)

## Story order

1. **US-15-01** Device strip chrome framework (input/output registries, slot width)
2. **US-15-02** Kick bench + `kickModel` (parallel with 03 after 01)
3. **US-15-03** Mono drum output panels (all four M13 drums)
4. **US-15-04** Dynamics input + output panels
5. **US-15-20** PO demo

## Locked decisions

- No new device types for kick model variants — `kickModel` param + DSP branch
- `DeviceSlot.gain` / `pan` remain universal in engine; UI chooses visibility
- Slot order: `[Tool][Mod?][Lfo?][Input?][Card][Output?]`
- Kick card: no tabs; ~480px width; preview 2/3 + model segment 1/3

## Supersedes (M13)

- Kick 3-tab strip (Body / Trans / Amp) → kick bench (US-15-02)
- Shared Pan+Gain level panel for drums → `DrumMonoOutputPanel` (US-15-03)
