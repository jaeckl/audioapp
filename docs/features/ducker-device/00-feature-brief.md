# Ducker Device — Feature Brief

## User-Visible Goal

Add a dedicated **Ducker** audio FX: duck this track’s level when a chosen **sidechain source** is loud (classic kick→bass pump). Source picker is a combobox with track icons (track output or device on another track). Off = no ducking.

## Non-Goals

- Hardware / live mic input (v1.1)
- Retrofitting compressor sidechain
- Vocoder / dual-path FX beyond ducker key
- Sends/returns bus system

## Type ID

| typeId | Name | Accent |
|--------|------|--------|
| `ducker` | Ducker | `#F472B6` |

## Reuse

- Graph edges from `audio_receiver` capture/inject path
- `buildRoutingSourceOptions` + track icons
- Dynamics chrome (input trim + GR meter)
- Envelope math patterns from compressor/gate

## Acceptance

1. Insert Ducker on bass track; pick kick track/device as sidechain → play → audible pump.
2. Source Off clears edge; invalid/cycle rejected with rollback.
3. JSON round-trip `sidechainSourceId` + knobs.
4. C++ test: two tracks, sidechain edge, GR when key loud.
5. Deploy demo on device.
