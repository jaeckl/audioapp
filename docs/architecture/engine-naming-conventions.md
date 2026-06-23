# Engine naming conventions — `engine_juce/`

Every device in the engine has a family of types with different suffixes. This document maps
each suffix to its role, thread, and serialization behaviour.

## Quick reference

| Suffix | Role | Thread | Persisted? | Example |
|---|---|---|---|---|
| `*Model` | UI-centred parameter bag (normalized values, converters) | Control | **Yes** — round-trips to JSON | `FilterModel`, `BassSynthModel` |
| `*Params` | DSP-centred parameter bag (real Hz/dB/Q, flat PODs) | Control→Audio (const) | Sometimes (simpler devices) | `OscillatorParams`, `CompressorParams` |
| `*ParamsPlayback` | Audio-thread snapshot (same struct as `*Params` but owned by `DeviceVariantParams`) | Audio (const) | No | `DelayParamsPlayback` |
| `*Runtime` | Mutable sample-rate state (phases, envelopes, filters) | Audio (mutated) | No | `SubtractiveSynthRuntime` |
| `*Panel` (Input/Output) | Per-device I/O stage variant (gain, pan, trim) | Control→Audio | **Yes** — part of `DeviceConfig` | `StereoOutputPanel`, `DynamicsInputPanel` |
| `*Processor` | OOP wrapper owning one `Runtime` + `process(AudioBlock, ProcessContext)` | Audio | No | `KickProcessor`, `CompressorProcessor` |
| `*Algorithm` | Free-function DSP kernels (pure computation, no state) | Audio (called by Processor) | No | `KickAlgorithm`, `SubtractiveSynthAlgorithm` |
| `*DeviceType` | Bridge: model↔audio, factory, serialization | Control | — | `OscillatorDeviceType`, `CompressorDeviceType` |
| `*Runtime` (shared) | Per-dynamics value-tracker (envelope follower, GR meter) | Audio (mutated) | No | `DynamicsRuntime` |

## Detailed breakdown

### `*Model` — The UI contract

Holds **normalised** values (0–1 floats) that the UI slider/knob controls produce directly.
Has a `toPlaybackParams()` converter that maps from normalised to real engineering units
(Hz, dB, Q).

```cpp
struct FilterModel {
    float ffxCutoff = 0.6f;     // normalised 0-1
    float ffxResonance = 0.3f;  // normalised 0-1
    float ffxFilterMode = 0.0f; // normalised 0-1

    FilterParams toPlaybackParams() const {
        return { normalizedToFrequency(ffxCutoff),
                 normalizedToQ(ffxResonance),
                 static_cast<int>(std::lround(ffxFilterMode * 3.0f)) };
    }
};
```

**Analogous to:** MVC *Model* — the authority for what the UI sees and edits.
**Persisted:** Yes — round-trips to project JSON via `DeviceType::slotToVar/varToSlot`.

---

### `*Params` — The DSP contract

A flat POD struct with **real units** (Hz, dB, Q, seconds, ratio). The audio thread reads
this const. There are two sources:

- **Direct `*Params`** (simple devices like Oscillator, Compressor, Delay) — these types
  are stored directly in `DeviceInstance` inside `DeviceConfig` and are also the audio-thread
  params. No conversion needed because the UI already sends real engineering units.
- **Via `*Model::toPlaybackParams()`** (Filter, BassSynth, Sampler, etc.) — the `*Model`
  is in `DeviceInstance`, and `buildPlaybackNode()` calls `toPlaybackParams()` to produce
  the `*Params` that goes into `DeviceVariantParams`.

There is a naming inconsistency where `*ParamsPlayback` structs (e.g. `DelayParamsPlayback`)
live in `DeviceChain.hpp` alongside the `DeviceVariantParams` variant — these are strict
subsets of the full `*Params` found in `effects/DelayParams.hpp`, keeping only the fields
the audio thread needs.

**Analogous to:** MVC *View Model* / DTO — a thread-safe snapshot of what to render.
**Persisted:** *Some* — simple `*Params` types are persisted directly; complex ones go
through `*Model`.

---

### `*Runtime` — Mutable voice memory

Owned by the `*Processor`. Mutated by DSP kernels on the audio thread every `process()` call.
Holds evolving state: oscillator phases, envelope values, filter biquad coefficients,
voice steal indices.

**Analogous to:** The *hidden mutable state* of the View's rendering engine — invisible to
the user but essential for producing sound.
**Persisted:** Never.

---

### `*Panel` — I/O stage descriptors

`InputPanelParams` and `OutputPanelParams` are `std::variant<...>` types stored in
`DeviceConfig`. Each device selects the panel variant that matches its I/O capabilities:

| Panel variant | Used by | Fields |
|---|---|---|
| `EmptyPanel` | Most devices (no special input) | — |
| `DynamicsInputPanel` | Compressor, Gate, Limiter, Expander | `trim` |
| `MonoOutputPanel` | Kick, Snare, Clap, Crash, Cymbal, TrackGain | `gain` |
| `StereoOutputPanel` | Everything else | `gain`, `pan` |

Each panel also owns its DSP `applyFromScratch()`/`applyInPlace()` methods — the panel
struct is the single source of truth for how its gain/pan is applied at the sample level.

**Analogous to:** MVC *View* — the outermost presentation layer of a device's signal path.
**Persisted:** Yes — part of `DeviceConfig`.

---

### `*Processor` — The OOP wrapper

Inherits `DeviceProcessor`. Owns one `*Runtime` member. Its `process()` virtual method:

1. Reads the modulated `*Params` from `ProcessContext`
2. Feeds it, the `Runtime`, and audio buffers into `*Algorithm` free functions
3. Applies output gain/pan via the panel type's `applyFromScratch()`

Created by `IDeviceType::createProcessor(ProcessorArena&)` on the control thread, lives
in a `ProcessorArena` on the audio thread.

```cpp
class KickProcessor : public DeviceProcessor {
    KickGeneratorRuntime runtime_;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override {
        // ... render into scratch ...
        StereoOutputPanel::applyFromScratch(
            ctx.scratch.scratch, block, block.numSamples,
            ctx.scratch.perFrameGain, ctx.scratch.perFramePan);
    }
};
```

**Analogous to:** MVC *Controller* — wires input (params+runtime) to output (audio).
**Persisted:** Never.

---

### `*Algorithm` (was `*Generator`) — DSP kernels

Free functions in their own header/source. Pure computation — no state, no member variables.
Called by `*Processor` with explicit parameter structs and runtime references.

```cpp
// In SubtractiveSynthAlgorithm.hpp
void mixSubtractiveMidiNotesBlock(float* scratch, int frames, double sampleRate,
    int bpm, double playheadBeat,
    const SubtractiveMidiNoteRegion* regions, int regionCount,
    const SubtractiveSynthParams& params,
    SubtractiveSynthRuntime& runtime,
    ...) noexcept;
```

**Named `*Algorithm`** because they are the DSP *algorithm* — the how, separated from
the when (`Processor`) and the what (`Params`).
**Persisted:** Never.

---

### `*DeviceType` — The bridge

The only type that has *all* the knowledge about a device kind. Implements `IDeviceType`:

| Method | Responsibility |
|---|---|
| `typeId()` | Canonical string identifier (e.g. `"kick_generator"`) |
| `createDefault()` | Builds a `DeviceSlot` with correct panels, params, bypass policy |
| `setParameter()` | Routes UI parameter ID to the right field in model or panel |
| `buildPlaybackNode()` | Packs `DeviceSlot` → `DeviceNodePlayback` (flat audio-thread POD) |
| `createProcessor()` | Instantiates the right `*Processor` subclass in a `ProcessorArena` |
| `slotToVar()` / `varToSlot()` | JSON serialisation round-trip |

**Analogous to:** MVC *Factory + Repository* — knows how to create, serialize, and
translate between all representations of one device type.
**Persisted:** No (but its methods read/write persisted state).

## Thread safety summary

```
                                CONTROL THREAD                          AUDIO THREAD
                                ==============                         =============

  *DeviceType  ──┬── createDefault()     ──► DeviceSlot
                 ├── setParameter()       ──► DeviceSlot (mutates)
                 ├── varToSlot()          ──► DeviceSlot (deserialise)
                 ├── slotToVar()          ◄── DeviceSlot (serialise)
                 ├── createProcessor()    ──► ProcessorArena (placement-new)
                 └── buildPlaybackNode()  ──► DeviceNodePlayback ──────► (read-only snapshot)

  *Model        ── stored in DeviceSlot::instance                       (not on audio thread)
  *Params       ── packed into DeviceVariantParams  ──────────────────► (read-only, via modulatedParams)
  *Runtime      ── (owned by Processor, never touched here)            (mutable per process())
  *Processor    ── created here, then arena pointer given to           (virtual process() called)
                   TrackPlaybackSnapshot
  *Algorithm    ── (never called on control thread)                    (called by Processor::process())
  *Panel        ── stored in DeviceConfig             ─────────────────► (read-only gain/pan values)
                   applyFromScratch/applyInPlace                       (called by Processor or orchestrator)
```

## MVC analogy (for intuition)

```
┌──────────────────────────────────────────────────────────┐
│  UI (Flutter)                                            │
│  Sliders, knobs, buttons    ◄── snapshot ── *Model       │
└──────────────────┬───────────────────────────────────────┘
                   │ setParameter(paramId, value)
                   ▼
┌──────────────────────────────────────────────────────────┐
│  *DeviceType            (Controller / Factory)           │
│  ─ routes params to *Model or *Panel                     │
│  ─ builds DeviceNodePlayback for audio thread            │
│  ─ creates *Processor in arena                           │
│  ─ serializes/deserializes to JSON                       │
└──────┬───────────────────────────────────────────────────┘
       │ buildPlaybackNode()         │ createProcessor()
       ▼                             ▼
┌─────────────┐              ┌─────────────────────┐
│ *Model       │              │ *Processor          │
│ *Params      │  snapshot    │   owns *Runtime     │  (Controller)
│ *Panel       │  (Model)     │   calls *Algorithm  │
└─────────────┘              └─────────┬───────────┘
                                       │ process()
                                       ▼
                               ┌─────────────────┐
                               │ *Algorithm       │  (Service / Use Case)
                               │ DSP kernels      │
                               │ pure computation │
                               └─────────────────┘
```

The JSON file (`*.audioapp`) is the **persistence store** — it round-trips `*Model` values
and `*Panel` values, but never `*Runtime` or `*Processor` state.

## Naming anti-patterns to avoid

| Don't use | Because |
|---|---|
| `*Manager` | Implies everything-management — usually a SRP violation |
| `*Utils` / `*Helpers` | Generic dumping ground. Prefer `*Algorithm` for DSP, `*Processor` for OOP |
| `*Generator` for headers | Sounds like it generates audio directly; renamed to `*Algorithm` because these are DSP kernels |
| `*Instance` | Was ambiguous — could mean model object or runtime instance. Replaced by `*Model` and `*Params` |