# Milestone 13 — Drum generators

Design docs: [docs/design/drum_generators/README.md](../../docs/design/drum_generators/README.md)

## Story order

1. **US-13-01** Kick generator (engine + strip) — in progress
2. **US-13-02** Snare generator
3. **US-13-03** Clap generator
4. **US-13-04** Cymbal / crash generator
5. **US-13-20** PO demo — full kit on timeline

## Locked decisions

- Monophonic per device (retrigger on new note)
- ~~Shared 3-tab strip pattern (Body / Trans or variant / Amp)~~ — **kick superseded by Kick bench (M15 / US-15-02)**
- Per-device accent color and envelope preview
- `kick_generator`, `snare_generator`, `clap_generator`, `cymbal_generator` type IDs
- Multiple kick engines via `kickModel` param — **not** separate device types (ADR-0008)
