# Canonical Vocabulary: Random Generator Modulator

## Type Identifiers

| Concept | Canonical Name | Type / Location | Notes |
|---------|---------------|----------------|-------|
| Engine enum value | `ModulatorType::RandomGenerator` (value 2) | `ModulationTypes.hpp` | Add `RandomGenerator = 2` to `enum class ModulatorType` |
| Type index | `2` (int) | `ModulationGraph::createLfo()` clamp range | Must expand clamp from `0,1` to `0,2` |
| Type string ID | `"random_generator"` | `RandomGeneratorModulatorType::typeId()` | Used in JSON serialization |
| Flutter constant | `ModulatorTypes.randomGenerator = 2` | `modulator_types.dart` | New class constant |
| Flutter label | `"RND"` | `ModulatorTypes.labelFor()` | Short 3-char tile label |

## Parameter Names

| Concept | Canonical Name | Type / Range | Default | Notes |
|---------|---------------|-------------|---------|-------|
| Rate | `rate` | float [0, 1] | 0.5 | Mapped to bpm-synced divisions or Hz (same mapping as LFO rate) |
| Smoothing | `smoothing` | float [0, 1] | 0.0 | 0=instant steps, 1=fully smoothed (linear slew between values) |
| Retrigger | `retrigger` | int [0, 2] | 1 (Sync) | Same enum as LFO/envelope: 0=Free, 1=Sync, 2=OnNote |
| Polarity | `polarity` | int [0, 1] | 0 (Bipolar) | 0=bipolar [-1,1], 1=unipolar [0,1] |

Note: `polarity` uses values 0/1 (not 0/1/2 as in LFO which has unipolar-neg). The Random Generator only needs bipolar/unipolar.

## Struct Names (C++)

| Concept | Canonical Name | File | Notes |
|---------|---------------|------|-------|
| Params struct | `RandomGeneratorParams` | `ModulatorParams.hpp` | New struct for variant |
| Modulator runtime | `RandomGeneratorRuntime` | (inline in `RandomGeneratorModulator.hpp`) | Tracks current value, last retrigger gen |
| Audio-thread modulator | `RandomGeneratorModulator` | `RandomGeneratorModulator.hpp` + `.cpp` | Implements `IModulator` |
| Type descriptor | `RandomGeneratorModulatorType` | `RandomGeneratorModulatorType.hpp` + `.cpp` | Implements `IModulatorType` |

## Flutter Names

| Concept | Canonical Name | File | Notes |
|---------|---------------|------|-------|
| Flutter type constant | `ModulatorTypes.randomGenerator` (= 2) | `modulator_types.dart` | |
| Flutter label | `"RND"` | `modulator_types.dart` → `labelFor()` | |
| Snapshot fields | `rate`, `smoothing` | `project_snapshot.dart` → `LfoSnapshot` | Added to existing params fields |
| Preview function | `randomGeneratorPreview()` | `modulator_math.dart` | Client-side preview curve |
| Properties layout | `_randomGeneratorLayout()` | `modulator_properties_panel.dart` | Panel layout method |