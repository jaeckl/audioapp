# Drum machine — default pad layout (presets)

**Status:** Accepted reference (documentation only)  
**Audience:** Anyone authoring drum kits / drum-machine presets  
**Applies to:** `drum_machine` 4×4 pad banks (MPC-style grid)

This document defines the **universal Bank A layout** used when creating
default and factory drum presets. It is the product standard for pad roles
and MIDI notes — not a runtime feature description.

## Goals

1. Match modern pad controllers (MPC ≥2.11 Chromatic C1, Ableton Push).
2. Keep core finger-drumming roles on the bottom row (Kick · Snare · CHH · OHH).
3. Keep pad order identical to ascending MIDI notes (keyboard / piano roll).
4. Stay compatible with our engine model: pad identity = MIDI note index
   (`DrumMachineModel`, bank grid bottom-left = lowest note).

## Non-goals

- Do **not** use Classic / legacy MPC note maps (A01=37, A02=36, …).
- Do **not** place Closed/Open hat on GM notes 42/46 for the *default*
  playable layout (those leave the bottom row). Optional GM import remap
  may be documented later as a separate preset flavor.

---

## Transport layer (fixed)

| Rule | Value |
|------|--------|
| Grid | 4×4, bottom-left = pad 1 / A01 |
| Bank A notes | **36–51** (C1 … D#2) |
| Order | Chromatic ascending left→right, bottom→top |
| Higher banks | Continue chromatic (B = 52–67, …) |

Same convention as modern Akai **Chromatic C1** and Ableton Drum Rack /
Push default quadrant.

---

## Role layer — Bank A (universal preset)

Visual (screen / hardware orientation — bottom row is home row):

```text
        Col0        Col1        Col2        Col3
Row3    Cowbell     Shaker      FX 1        FX 2
        48          49          50          51

Row2    Perc 1      Perc 2      Ride        Crash
        44          45          46          47

Row1    Clap/Rim    Tom Lo      Tom Mid     Tom Hi
        40          41          42          43

Row0    Kick        Snare       Closed HH   Open HH
        36          37          38          39
```

### Pad table

| Pad | Note | Name (preset label) | Typical content |
|-----|------|---------------------|-----------------|
| A01 | 36 | Kick | Kick / bass drum |
| A02 | 37 | Snare | Acoustic or electronic snare |
| A03 | 38 | Closed Hat | Closed hi-hat |
| A04 | 39 | Open Hat | Open hi-hat |
| A05 | 40 | Clap / Rim | Clap, rimshot, or side stick |
| A06 | 41 | Tom Lo | Low tom |
| A07 | 42 | Tom Mid | Mid tom |
| A08 | 43 | Tom Hi | High tom |
| A09 | 44 | Perc 1 | Conga, bongo, woodblock, etc. |
| A10 | 45 | Perc 2 | Second percussion / alt hit |
| A11 | 46 | Ride | Ride cymbal |
| A12 | 47 | Crash | Crash / splash |
| A13 | 48 | Cowbell | Cowbell or bell |
| A14 | 49 | Shaker | Shaker / tambourine |
| A15 | 50 | FX 1 | One-shot FX, riser hit, vocal stab |
| A16 | 51 | FX 2 | Second FX / spare |

### Required choke (when both hats exist)

| Group | Pads | Behavior |
|-------|------|----------|
| Hats | A03 (Closed HH) ↔ A04 (Open HH) | Closed cuts open (and vice versa if desired) |

Use the drum pad choke group already supported by the drum machine model.

---

## Preset authoring checklist

When building a new drum preset:

1. Map sounds to **notes 36–51** using the table above (empty pads OK).
2. Always fill **A01–A04** if the kit has kick/snare/hats.
3. Set hat choke between A03 and A04.
4. Use the **preset labels** in the Name column for pad names in the project /
   snapshot so the grid UI stays consistent across kits.
5. Prefer putting secondary articulations (ghost snare, hat tip, etc.) on
   higher banks or unused A09–A16 slots — do not move Kick/Snare/Hats off
   A01–A04.

Minimal viable kit: A01–A04 only. Full kit: fill through A12 at least.

---

## Relation to General MIDI

| Role | This layout note | GM percussion note |
|------|------------------|--------------------|
| Kick | 36 | 36 |
| Snare | 37 | 38 (Acoustic Snare) |
| Closed Hat | 38 | 42 |
| Open Hat | 39 | 46 |
| Clap | 40 | 39 |
| Crash | 47 | 49 |
| Ride | 46 | 51 |

Default presets optimize for **pad playability**, not 1:1 GM MIDI-file
playback. If a preset must answer strict GM files, document it as a separate
`gm-*` variant and remap roles onto GM note numbers (gaps on the 4×4 are OK).

---

## Factory MIDI beat library

Common genre drum loops for the content library are authored against this
pad map. Source catalog (step notation + tags):

- [`drum_beat_catalog.yaml`](drum_beat_catalog.yaml) — research patterns
- Codegen: `tools/generate_drum_beat_midi.py` → Dart pattern groups +
  `manifest.json` `midiClips` entries (`drums` + genre tags)

## References

- Modern MPC Chromatic C1 vs Classic MPC (mpc-tutor, Akai pad remap docs)
- Ableton Drum Rack / Push: C1 bottom-left quadrant
- Engine: `DrumMachineModel` (pad index = MIDI note), Flutter
  `DrumMachineDevicePanel` bank math
- Research canvas (session): `drum-pad-layout-research.canvas.tsx`
