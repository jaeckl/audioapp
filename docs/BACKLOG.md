# Implementation backlog

Planning for vertical slices. Product vision: [AGENT.md](../AGENT.md).

## UX iteration (device tabs + big knobs)

| # | Increment | Status |
|---|-----------|--------|
| 1 | `DeviceKnobSizes` + larger `RotaryKnob` touch targets | Done |
| 2 | `DeviceTabBar` — segmented device pages | Done |
| 3 | Sampler tabs: Sample / Env / Filter / Level + big knobs | Done |
| 4 | Collapsible device strip (~112dp collapsed) | Done |
| 5 | Fullscreen sampler editor — same tabs, editor-sized knobs | Done |
| 6 | Oscillator tabbed panel + big frequency knob | Done |
| 7 | Mixer channels use rotary knobs | Done |
| 8 | Transport overflow: tap tempo, loop length, export | Done |
| 9 | Duplicate clip (engine + double-tap clip menu) | Done |
| 10 | Nav “Project” label + competitive UX doc update | Done |

## Prior increments

| # | Increment | Status |
|---|-----------|--------|
| 1–10 | ADSR, filter, BPM, trim, delete, mixer, render, export, loop | Done |

## Next candidates

## Play Mode (milestone 10)

| Ticket | Slice | Status |
|--------|-------|--------|
| US-10-01 | Play tab workspace | Done |
| US-10-02 | Live noteOn/noteOff engine | Done |
| US-10-03 | MPC 4×4 pad grid + banks | Done |
| US-10-04 | Play keyboard (scale, octave, gliss) | Done |
| US-10-05 | Record arm toggle | Done |
| US-10-06 | Capture without transport play | Done |
| US-10-07 | ¼-beat quantize on commit | Done |
| US-10-08 | Entry: Play tab + track menu | Done |
| US-10-09 | Play widget + C++ tests | Done |

**Backlog (should-have):** chord/strum strips, choke groups, hold Y-slide aftertouch, mixer sheet from Play.

## Milestone 16 — Modulation & Automation Test Coverage

| Ticket | Slice | Status |
|--------|-------|--------|
| US-16-01 | Stacked LFO modulation test (engine) | Done |
| US-16-02 | Effect device modulation test (engine) | Done |
| US-16-03 | Common param gain/pan modulation test (engine) | Done |
| US-16-04 | Percussion generator modulation test (engine) | Done |
| US-16-05 | ADSR envelope modulator test (engine) | Done |
| US-16-06 | LFO polarity test (engine) | Done |
| US-16-07 | LFO sync-to-BPM test (engine) | Done |
| US-16-08 | Combined gain/pan mod+auto test (engine) | Done |
| US-16-09 | Effect device automation test (engine) | Done |
| US-16-10 | Flutter LFO bridge CRUD test | Done |
| US-16-11 | Flutter modulation widget test | Done |
| US-16-12 | Flutter snapshot parsing test | Done |
| US-16-13 | Flutter modulation persistence test | Done |

## Other candidates

- Clip resize
- Embed samples in project archive on save
- Piano roll velocity + undo
- Mixer as bottom sheet over arrangement
