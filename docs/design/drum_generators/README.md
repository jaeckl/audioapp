# Drum generators — design family (M13)

Synthesized **one-shot percussion instruments** as first-class devices. Each generator is monophonic (retrigger on new note), MIDI-triggered, and optimized for mobile strip UX.

## Why generators vs sample clips

| Approach | Best for |
|----------|----------|
| **Sample clips (M06)** | Acoustic loops, imported WAVs, timeline editing |
| **Drum generators (M13)** | Tunable electronic drums, low memory, param automation, instant audition from strip |

Generators coexist with sampler and subtractive synth on the same track chain.

## Shared product rules

- **Category:** Instrument (`DeviceNodeKind::*`)
- **Polyphony:** Monophonic per device instance (latest note retrigger)
- **MIDI:** Clip notes + live pads; velocity scales output
- **RT-safe:** No heap alloc in audio path; fixed voice state
- **Serialization:** `type` + `parameters` blob in `project.json` via `juce::JSON`
- **Strip UX:** 3-tab layout, accent color per drum, animated envelope preview, hold-to-test in fullscreen editor (later stories)

## Device lineup

| Device | `type` string | Accent | Tabs | Milestone story |
|--------|---------------|--------|------|-----------------|
| [Kick generator](kick_generator.md) | `kick_generator` | `#E85D4B` | Body · Trans · Amp | US-13-01 ✅ first |
| [Snare generator](snare_generator.md) | `snare_generator` | `#F0C14B` | Body · Snares · Amp | US-13-02 |
| [Clap generator](clap_generator.md) | `clap_generator` | `#E8A0C8` | Burst · Tone · Amp | US-13-03 |
| [Cymbal / crash](cymbal_crash_generator.md) | `cymbal_generator` | `#9AD4E8` | Metal · Decay · Amp | US-13-04 |

## Shared strip layout (360×320 design canvas)

```text
┌─ Tool rail ─ bypass · mod · (library later) ─────────────────┐
├─ Header ── [icon] Kick Generator │ Body │ Trans │ Amp ────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Envelope preview (pitch + amp curves, animated on hit)   │ │
│  └─────────────────────────────────────────────────────────┘ │
│     [Knob]      [Knob]      [Knob]     ← tab-specific params │
├─ Level panel ─ gain · pan ────────────────────────────────────┤
└───────────────────────────────────────────────────────────────┘
```

## Engine architecture

Follows M12 `IDeviceType` pattern (same as subtractive synth):

```text
KickGeneratorDeviceType → KickGeneratorInstance → KickGeneratorParams
KickGenerator.cpp       → mixKickMidiNotesBlock / kickGeneratorSample
DeviceChain             → DeviceNodeKind::KickGenerator
LivePerformance         → LiveInstrumentKind::KickGenerator
```

## Milestone M13 (planned)

See [milestone-13.md](../../milestones/milestone-13.md) and `tickets/milestone-13/`.

Implementation order: **Kick → Snare → Clap → Cymbal → PO demo**.
