# US-11-06: Mix, Filter, and Amp strip tabs

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I edit **mix**, **LP12 filter**, and **amp envelope** from dedicated strip tabs so the subtractive synth matches the sampler’s four-tab mental model (minus sample-specific tabs).

## Goal

Complete strip editor — all core sound design without opening fullscreen.

## Tab contents

| Tab | Controls |
|-----|----------|
| **Mix** | osc1/osc2/noise levels, mix mode selector |
| **Filter** | cutoff, resonance, filter ADSR, env amount (**LP12 only**) |
| **Amp** | amp ADSR (gain/pan remain on shared level panel) |

## Scope

- Register Mix, Filter, Amp in `DeviceContainerTabs.forDeviceType('subtractive_synth')`
- Reuse ADSR knob row + filter knob patterns from sampler where possible
- Remove duplicate mini controls from US-11-02 placeholder when superseded

## Out of scope

- LFO tab
- Fullscreen (US-11-07)
- Automation lanes (M08 deferred stories)

## Acceptance criteria

- [ ] Four tabs: Osc | Mix | Filter | Amp
- [ ] Filter tab labels clarify **LP12** (no HP/BP UI)
- [ ] All params live-update audio on device
- [ ] Tab selection persists while switching tracks and back (per-device state)
- [ ] Widget tests per tab mount

## Demo script (on-device, ~45s)

1. Mix tab → noise + am mode → Filter tab → envelope sweep on cutoff → Amp tab → shorten release.

## Depends on

US-11-05

## Companion stories

- [UX/UI](US-11-06-ux-ui.md)
- [Interaction](US-11-06-interaction.md)

## Status

**Todo**
