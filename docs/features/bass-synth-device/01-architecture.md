# Architecture: Bass Synth Device

## Overview

`BassSynth` is a **wrapper device** that reuses the full `SubtractiveSynth` audio engine with a curated 16-parameter control set. It follows the exact same device registration pattern as `SubtractiveSynth`, `KickGenerator`, etc.

## Architecture diagram

```
┌─────────────────────────────────────────────────────┐
│  Flutter UI                                          │
│  BassSynthDevicePanel (Tone | Filter | Char tabs)    │
│  BassSynthDeviceStrip (compact card wrapper)          │
│  DevicePickerSheet (list entry)                       │
│  DeviceSnapshot (bass fields + existing fields)       │
└──────────────┬────────────────────────────────────────┘
               │ JSON snapshot
               ▼
┌──────────────────────────────────────────────────────┐
│  C++ DeviceRegistry → findForSlot()                   │
│  → BassSynthDeviceType (IDeviceType impl)             │
│    ├─ createDefault()                                 │
│    ├─ toSnapshotState() / slotFromSnapshot()           │
│    ├─ setParameter()                                   │
│    ├─ buildPlaybackNode() ─┐                           │
│    └─ buildLiveInstrument()─┤                          │
└─────────────────────────────┼──────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────┐
│  BassSynthInstance (16 curated params)                 │
│  toPlaybackParams() → SubtractiveSynthParams            │
│  (fills 50 params from 16 bass params + hardcoded)     │
└─────────────────────────────┬──────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────┐
│  DeviceNodeKind::BassSynth                             │
│  → std::get<SubtractiveSynthParams>(...)              │
│  → mixSubtractiveMidiNotesBlock()                     │
│    (identical audio path as SubtractiveSynth)          │
└──────────────────────────────────────────────────────┘
```

## Threading model

- **Control thread**: `BassSynthDeviceType` methods, `BassSynthInstance` parameter changes, snapshot serialization
- **Audio thread**: `DeviceNodePlayback` (holds `SubtractiveSynthParams`), `LiveInstrumentSnapshot` (holds `subtractive` field), `SubtractiveSynthRuntime`
- The mapping from `BassSynthInstance` → `SubtractiveSynthParams` happens on the control thread during `buildPlaybackNode` / `buildLiveInstrument`

## Error model

- Unknown parameter IDs: return `DeviceParameterResult{handled: false}` (no error)
- Out-of-range values: clamp to [0, 1] or discrete range
- Device registration: `BassSynthDeviceType` is registered in `createBuiltIn()`; if not found, `find()` returns nullptr

## Persistence model

- `BassSynthInstance` state is serialized via `DeviceState` (shared DTO with bass-prefixed fields plus reused common fields)
- JSON field names are the same as `DeviceState` field names (prefixed with `bass` for bass-specific params, reuse existing for shared params like `gain`, `filterCutoff`)
- Full save/load round-trip: `slot → toSnapshotState() → JSON → slotFromSnapshot()`

## UI/state sync model

- Flutter `DeviceSnapshot` receives `bass*` fields from JSON engine snapshot
- `DeviceSnapshot.copyWith(bassOscShape: v)` → bridge → engine `setParameter('bassOscShape', v)` → `BassSynthDeviceType`
- Modulatable params: subset of bass params can be modulated via LFO
- Automation: `filterCutoff` and `gain` support automation clips