# Architecture Contract

## Existing Code to Reuse
- `paramIdFromString` (AutomationPlayback.cpp) — correct, no changes needed
- `applyAutomationValue` (AutomationPlayback.cpp) — correct dispatch via enum switch
- `applyModulation` overloads (DeviceChain.cpp) — correct
- `applySubtractiveModulation` (SubtractiveSynth.cpp) — correct duplicate of the DeviceChain overload
- `mixSubtractiveMidiNotesBlock` per-frame loop (SubtractiveSynth.cpp) — correct
- `processDeviceChain` block-rate loops (DeviceChain.cpp) — correct

## Architecture Decision
The architecture is sound. The fix requires **correcting the runtime values**, not the routing. Specific decisions:

1. **No changes to enum values or paramId strings** — the mapping is verified correct.
2. **Instrument the modulation path** — add temporary trace logging to capture actual `edge.amount`, `lfoOut`, `modAmount`, and resulting `filterCutoff` during playback.
3. **Check the modulation amount flow** from UI → bridge → `assignModulation` → `ModulationGraph` → `PlaybackSnapshot` → audio thread.
4. **Verify `std::get_if` safety** — ensure the variant always holds the expected type.

## Module Boundaries
| Module | File(s) | Responsibility |
|--------|---------|----------------|
| DeviceChain | DeviceChain.cpp, DeviceChain.hpp | Block-rate + per-frame DSP routing |
| AutomationPlayback | AutomationPlayback.cpp, AutomationPlayback.hpp | Param ID resolution, automation envelope eval |
| SubtractiveSynth | SubtractiveSynth.cpp, SubtractiveSynth.hpp | Per-sample synth DSP including filter |
| ProjectEngine | ProjectEngine.cpp, ProjectEngine.hpp | Control thread → audio thread snapshot builder |
| ModulationGraph | modulation/ModulationGraph.cpp, ModulationGraph.hpp | LFO state + edge management |
| Device Types | devices/SubtractiveSynthDeviceType.cpp | Control-thread param setter |
| Flutter Bridge | app_flutter/lib/bridge/ | Flutter → engine parameter request |

## Threading/Async Boundaries
- **Control thread** (lock-held): `paramIdFromString`, `automationClipPlaybackFromClip`, `rebuildTrackPlaybackLocked`, `assignModulation`
- **Audio thread** (lock-free): `processDeviceChain`, `applyDspAutomationAtBeat`, `applyDspModulationAtFrame`, `mixSubtractiveMidiNotesBlock`, `applySubtractiveModulation`, `applyAutomationValue`

## Ownership Boundaries
- `AutomationClip.paramId` string → owned by control thread, consumed by `paramIdFromString` during snapshot rebuild
- `ModulationEdge.paramId` string → owned by control thread
- `AutomationClipPlayback.localParamId` uint16 → resolved on control thread, consumed on audio thread
- `SubtractiveSynthParams.filterCutoff` → owned by audio thread (in `DeviceVariantParams`)

## Error Model
- `paramIdFromString` returns 0 for unknown params → silently no-ops on audio thread
- `std::get_if` fails → `applyAutomationValue` silently no-ops
- Modulation edges with `lfoId >= lfoCount` → silently skipped
- All failures silent (no exceptions on audio thread)

## Persistence Model
- No changes needed — serialization uses stable strings (`"filterCutoff"`) which already match

## UI/State Synchronization
- No changes needed — the manual knob path already works
