# API and Data Contracts

## 1. paramIdFromString

```cpp
uint16_t paramIdFromString(const char* name, DeviceNodeKind kind) noexcept;
```

**Owner**: AutomationPlayback.cpp line 21
**Input**: `name` = stable param string (e.g. "filterCutoff"), `kind` = device kind
**Output**: `localParamId` uint16 (0 for unknown/empty)
**Threading**: Control thread (string ops OK)
**Known callers**:
- ProjectEngine.cpp line 1161 (modulation edges)
- ProjectEngine.cpp line 1186 (automation clips)
**Verification**: "filterCutoff" + SubtractiveSynthKind → 0 (SubtractiveParam::FilterCutoff) ✓

## 2. applyAutomationValue

```cpp
void applyAutomationValue(DeviceVariantParams& params, DeviceNodeKind kind,
                          uint16_t localParamId, float value) noexcept;
```

**Owner**: AutomationPlayback.cpp line 442
**Input**: `params` (mutated in-place), `kind`, `localParamId`, `value` (0..1, clamped)
**Output**: None (mutates params)
**Threading**: Audio thread
**SubtractiveSynth case** (line 477-523): Switches on `SubtractiveParam`, writes to `SubtractiveSynthParams` fields
**FilterCutoff** (line 479): `p->filterCutoff = value;` → CORRECT

## 3. applyModulation overloads (DeviceChain.cpp)

```cpp
void applyModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept;
```

**Owner**: DeviceChain.cpp line 106 (anonymous namespace)
**Input**: `p` (mutated), `modAmount` (signed), `localParamId`
**Output**: None
**FilterCutoff** (line 108): `p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f)` → CORRECT

## 4. applySubtractiveModulation (SubtractiveSynth.cpp)

```cpp
static void applySubtractiveModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept;
```

**Owner**: SubtractiveSynth.cpp line 94 (anonymous namespace)
**Input**/Output: Same as 3 above
**FilterCutoff** (line 96): Same code as 3 above → CORRECT
**Note**: Must be kept in sync with 3; any new params added to one must be added to the other.

## 5. applyDspAutomationAtBeat

```cpp
void applyDspAutomationAtBeat(DeviceVariantParams& params, DeviceNodeKind kind,
                              uint16_t deviceIndex, double beat,
                              const AutomationClipPlayback* clips, int clipCount) noexcept;
```

**Owner**: AutomationPlayback.cpp line 692
**Input**: `params` (mutated), `kind`, `deviceIndex`, `beat` (absolute timeline), `clips` array, `clipCount`
**Logic**: Filters clips by `deviceIndex`, skips gain/pan, checks beat bounds, evaluates envelope, calls `applyAutomationValue`
**Threading**: Audio thread

## 6. applyDspModulationAtFrame

```cpp
void applyDspModulationAtFrame(DeviceVariantParams& params, DeviceNodeKind kind,
                               int lfoFrame, int framesToProcess,
                               const float* lfoValues, int lfoCount,
                               const ModulationEdgePlayback* modEdges, int modEdgeCount) noexcept;
```

**Owner**: DeviceChain.cpp line 287 (anonymous namespace)
**Note**: For non-subtractive devices this is used in `dspParamsAtFrame`. For SubtractiveSynth it is NOT called here — modulation is done per-frame inside `mixSubtractiveMidiNotesBlock` instead.

## 7. mixSubtractiveMidiNotesBlock

```cpp
void mixSubtractiveMidiNotesBlock(float* monoOut, int numFrames, double sampleRate,
    int bpm, double playheadStartBeat, const SubtractiveMidiNoteRegion* notes, int noteCount,
    const SubtractiveSynthParams& params, SubtractiveSynthRuntime& runtime,
    const AutomationClipPlayback* automationClips, int automationClipCount,
    const uint16_t* automationDeviceIndex,
    const float* lfoValues, int lfoCount, int lfoStride,
    const ModulationEdgePlayback* modEdges, int modEdgeCount,
    const uint16_t* modulationDeviceIndex) noexcept;
```

**Owner**: SubtractiveSynth.cpp line 509
**Automation** (lines 623-635): Correctly creates `frameParams` copy, wraps in variant, applies automation, extracts back.
**Modulation** (lines 636-652): Iterates edges filtered by `modulationDeviceIndex`, reads `lfoOut` from `lfoValues[edge.lfoId * lfoStride + frame]`, computes `modAmount`, calls `applySubtractiveModulation`.

## 8. ProjectEngine.assignModulation

```cpp
bool ProjectEngine::assignModulation(int lfoId, const std::string& deviceId,
                                     const std::string& paramId, float amount);
```

**Owner**: ProjectEngine.cpp line 961
**Input**: `lfoId`, `deviceId`, `paramId` string, `amount` float
**Calls**: `modulationGraph_.assignModulation(lfoId, deviceId, paramId, amount)`
**Threading**: Control thread (lock held)
**Concern**: Is `amount` correctly passed from Flutter? Check bridge layer.

## 9. Flutter → Engine Modulation Assignment

**Need to verify**: The Flutter bridge calls `assignModulation` (line 961) from a MethodChannel. The `amount` value must be checked — if the Flutter side sends 0.0 or a near-zero value for filterCutoff modulation, no audible change will occur.

## Key Gap: LFO buffer stride (lfoStride) in mixSubtractiveMidiNotesBlock

In DeviceChain.cpp lines 652-655:
```cpp
hasMod ? lfoValues : nullptr, hasMod ? lfoCount : 0, hasMod ? framesToProcess : 0,
hasMod ? modEdges : nullptr, hasMod ? modEdgeCount : 0,
```

The 3rd param (`framesToProcess`) is passed as `lfoStride`. This matches the LFO buffer layout created in ProjectEngine.cpp line 584: `lfoValues[i * framesToProcess + frame]`. → CORRECT
