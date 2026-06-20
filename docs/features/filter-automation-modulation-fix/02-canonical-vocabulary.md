# Canonical Vocabulary

| Concept | Canonical Name | Type/File | Notes |
|---------|---------------|-----------|-------|
| Parameter ID string | `paramId` | `std::string` in `AutomationClip`, `ModulationEdge` | Serialized stable name; "filterCutoff" |
| Device-local parameter ID | `localParamId` | `uint16_t` in `AutomationClipPlayback`, `ModulationEdgePlayback` | Resolved from string by `paramIdFromString` |
| Subtractive filter cutoff | `filterCutoff` | `float` in `SubtractiveSynthParams` | Normalized 0..1, default 0.75 |
| Automation clip playback struct | `AutomationClipPlayback` | `AutomationTypes.hpp` line 177 | `deviceIndex`, `localParamId`, clips |
| Modulation edge playback struct | `ModulationEdgePlayback` | `AutomationTypes.hpp` line 186 | `deviceIndex`, `localParamId`, `lfoId`, `amount` |
| Device params variant | `DeviceVariantParams` | `DeviceChain.hpp` line 84 | `std::variant<OscillatorParams, SubtractiveSynthParams, ...>` |
| Filter cutoff Hz conversion | `normalizedCutoffToHz` | `SamplerFilter.hpp` | Maps 0..1 to Hz |
| SubtractiveParam enum | `SubtractiveParam::FilterCutoff` | `AutomationTypes.hpp` line 49 | Value 0 |
| Common param enum | `CommonParam::Gain`, `Pan`, `Bypass` | `AutomationTypes.hpp` line 22 | Values 0, 1, 2 |
| Modulation amount | `amount` | `float` in `ModulationEdge`, `ModulationEdgePlayback` | Signed; bipolar or unipolar |
| LFO output value | `lfoOut` | `float` in LFO buffer | Bipolar -1..1 (or unipolar 0..1 based on polarity) |
| LFO stride | `lfoStride` | `int` param to `mixSubtractiveMidiNotesBlock` | = `framesToProcess` (must match buffer layout) |
| Per-frame modulation | `applySubtractiveModulation` | `SubtractiveSynth.cpp` line 94 | Local copy of DeviceChain overload; must stay in sync |
| Per-frame automation | `applyDspAutomationAtBeat` | `AutomationPlayback.cpp` line 692 | Iterates clips, evaluates envelope, applies value |
| Modulated params | `modulatedParams` | Local in `processDeviceChain` | Copy of `node.params`, mutated for block-rate devices |
| Frame params | `frameParams` | Local per-frame in `mixSubtractiveMidiNotesBlock` | Per-frame copy mutated by automation + modulation |
