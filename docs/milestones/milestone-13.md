# Milestone 13 — Drum generators

**5 stories (planned)** — see [roadmap](roadmap.md) · [story_manifest.yaml](../../tickets/story_manifest.yaml)

| US | Title | Status |
|----|-------|--------|
| US-13-01 | Kick generator — engine + strip | In progress |
| US-13-02 | Snare generator | Todo |
| US-13-03 | Clap generator | Todo |
| US-13-04 | Cymbal / crash generator | Todo |
| US-13-20 | M13 PO demo — drum kit on timeline | Todo |

## Design docs

[docs/design/drum_generators/](../design/drum_generators/README.md)

## Product locks

- **Monophonic** per generator instance (retrigger)
- **MIDI-triggered** (clips + live pads)
- **Coexist** with sampler, subtractive synth, oscillator
- Shared **3-tab strip** pattern per device

## PO demo (US-13-20)

One track per generator → MIDI pattern → play → save/reload → mix with subtractive bass on track 2.
