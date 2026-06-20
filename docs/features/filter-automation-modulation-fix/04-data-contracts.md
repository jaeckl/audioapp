# Data Contracts

## AutomationClip model (control thread)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `id` | `std::string` | empty | Unique clip ID |
| `homeTrackId` | `std::string` | empty | Arrangement lane track |
| `startBeat` | `double` | 0.0 | Clip start position |
| `lengthBeats` | `double` | 4.0 | Clip duration |
| `deviceId` | `std::string` | empty | Target device ID |
| `paramId` | `std::string` | empty | "filterCutoff" for this bug |
| `points` | `vector<AutomationPoint>` | empty | Envelope breakpoints |

## AutomationClipPlayback (audio thread snapshot)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `deviceIndex` | `uint16_t` | 0 | Index into current track's device chain |
| `localParamId` | `uint16_t` | 0 | Resolved by `paramIdFromString` |
| `clipStartBeat` | `float` | 0.0f | Copied from model |
| `clipLengthBeats` | `float` | 4.0f | Copied from model |
| `pointCount` | `int` | 0 | Number of valid points (max 256) |
| `points[256]` | `AutomationPointPlayback[]` | {} | Envelope (beat, value) |

## ModulationEdge (control thread)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `lfoId` | `int` | 0 | LFO index in ModulationGraph |
| `deviceId` | `std::string` | empty | Target device ID |
| `paramId` | `std::string` | empty | "filterCutoff" for this bug |
| `amount` | `float` | 0.0f | Modulation depth (critical field) |

## ModulationEdgePlayback (audio thread snapshot)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `deviceIndex` | `uint16_t` | 0 | Index into device chain |
| `localParamId` | `uint16_t` | 0 | Resolved by `paramIdFromString` |
| `lfoId` | `uint16_t` | 0 | Index into LFO buffer |
| `amount` | `float` | 0.0f | Copied from ModulationEdge |

## LFO buffer layout

| Property | Value | Notes |
|----------|-------|-------|
| Layout | `lfoValues[lfoId * framesToProcess + frame]` | Created ProjectEngine.cpp:584 |
| Range | Bipolar -1..1 or unipolar 0..1 | Depends on LFO polarity setting |
| Value type | `float` | Per-frame, per-LFO |

## SubtractiveSynthParams.filterCutoff

| Property | Value |
|----------|-------|
| Type | `float` |
| Range | 0.0 .. 1.0 (normalized) |
| Default | 0.75 |
| Hz mapping | `normalizedCutoffToHz(normalized)` in SamplerFilter.hpp |
| Clamping | Normalized value clamped before Hz conversion |

## Critical Data Dependency Chain

```
Flutter slider drag
  → MethodChannel setParameter("filterCutoff", value)
    → SubtractiveSynthDeviceType.setParameter(...)
      → instance.filterCutoff = value  (SubtractiveSynthDeviceType.cpp:198)
        → rebuildTrackPlaybackLocked()
          → buildPlaybackNode() → toPlaybackParams()
            → DeviceNodePlayback.params → SubtractiveSynthParams.filterCutoff

Automation clip targeting "filterCutoff"
  → paramIdFromString("filterCutoff", SubtractiveSynthKind) → 0  (AutomationPlayback.cpp:51)
    → AutomationClipPlayback.localParamId = 0
      → applyDspAutomationAtBeat()
        → applyAutomationValue(..., localParamId=0, value)
          → SubtractiveParam::FilterCutoff: p->filterCutoff = value;

Modulation edge "filterCutoff"
  → paramIdFromString("filterCutoff", SubtractiveSynthKind) → 0  (ProjectEngine.cpp:1161)
    → ModulationEdgePlayback.localParamId = 0
      → mixSubtractiveMidiNotesBlock() per-frame loop
        → applySubtractiveModulation(frameParams, modAmount, pid=0)
          → SubtractiveParam::FilterCutoff: p.filterCutoff = clamp(p.filterCutoff + modAmount, 0, 1);
```
