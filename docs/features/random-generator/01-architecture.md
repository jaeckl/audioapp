# Architecture: Random Generator Modulator

## Architecture Decision

The Random Generator follows the **exact same pattern** as `LfoModulatorType` / `EnvelopeModulatorType`:

1. A new `RandomGeneratorParams` struct added to the `ModulatorParams` variant
2. A new `RandomGeneratorModulator` class (implements `IModulator`) for audio-thread evaluation
3. A new `RandomGeneratorModulatorType` class (implements `IModulatorType`) for control-thread descriptor
4. Registration in `ModulationGraph::ModulationGraph()` constructor
5. Bridge is already generic enough — no bridge changes needed (uses existing `createLfo` + `updateLfoParam`)
6. Flutter: new type constant, new `ModulatorSnapshot` fields, new layout in properties panel, new preview math

## Module Boundaries

| Module | Responsibility |
|--------|---------------|
| `engine_juce` | Random generator state machine, realtime-safe evaluation, serialization |
| `native_bridge` | Pass-through only (no changes needed) |
| `app_flutter` | UI tile, properties panel, client-side preview curve |

## Threading / Async Boundaries

- `RandomGeneratorModulator::evaluate()` runs on the **audio thread** — must be realtime-safe (no allocations, no locks, no I/O)
- `RandomGeneratorModulatorType` methods run on the **control thread** (setParameter, createDefault, serialize)
- `ModulationGraph::rebuildPlayback()` is called from the control thread and re-creates all modulators in the arena
- Flutter bridge calls are dispatched on the platform thread and forwarded synchronously to the engine

## Error Model

- Unknown parameter IDs → `setParameter()` returns `false` (already handled by existing `updateLfoParam` path)
- Invalid rate/smoothing values → clamped to [0, 1] range
- Random number generation → uses `thread_local` or local `std::mt19937` seeded once per modulator creation (control thread seed, audio thread consumption)

## Persistence Model

- Serialization via `paramsToVar()` / `varToParams()` (follows existing LFO/Envelope pattern)
- JSON shape: `{"type": "random_generator", "id": N, "rate": 0.5, "smoothing": 0.0, "retrigger": 1, "polarity": 0}`
- Stored within the existing `modulators` array in project JSON (same `recordsToVar`/`recordsFromVar` pipeline)

## UI / State Synchronization Model

- Flutter receives full modulator list in `getProjectSnapshot` response after every mutation
- `LfoSnapshot` (will be renamed/generalized — but for MVP, extend existing class) holds all modulator state
- `ModulatorPropertiesPanel` dispatches to `_randomGeneratorLayout()` based on `modulatorType == 2`
- Client-side preview in `ModulatorMath` computes stepped/smoothed random values for the tile waveform