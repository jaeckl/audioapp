# Integration Plan

## Recommended Implementation Order

1. **P1 (Automation Debug Trace)** + **P2 (Modulation Debug Trace)** in parallel
2. **P3 (Amount Value Validation)** — sequential, after P1/P2 results
3. **P4 (Flutter Bridge Check)** — sequential, after P3 identifies the issue
4. **P5 (FilterCutoff Modulation Test)** — sequential, designed based on findings

## Parallel Execution

| Package | Can Run With | Must Be After |
|---------|-------------|---------------|
| P1: Automation trace | P2 | Nothing |
| P2: Modulation trace | P1 | Nothing |
| P3: Amount validation | Nothing | P1, P2 |
| P4: Flutter bridge | Nothing | P3 |
| P5: Unit test | Nothing | P1, P2 |

## Shared Files Requiring Care
- `ProjectEngine.cpp` — P1 writes trace, P3 reads amount, P4 reads nothing on engine side. Minimal conflict risk.
- `DeviceChain.cpp` — P2 writes trace only. No structural changes.
- `SubtractiveSynth.cpp` — P2 writes trace only. No structural changes.

## Contract Gaps or Risks

### Risk 1: The "saw-wave stabs" sound vs "filter sweep"
The user hears "multiple stabs" rather than a filter sweep from a saw-wave automation clip. This is likely because `normalizedCutoffToHz(0.0)` maps to near-0 Hz (effectively mute), and the filter opens as value climbs. The result sounds like gain/gate modulation rather than tonal filter sweep. This is expected behavior of a lowpass filter with very low cutoff — it's not a routing bug.

### Risk 2: LFO modulation not audible
This is the primary concern. Three hypotheses:
1. **amount too small**: `assignModulation` is called with `amount ≈ 0` or very small
2. **Additive modulation range too small**: `filterCutoff` at 0.75 + `0.2 * 1.0 = 0.95` might not sound different enough
3. **Bipolar LFO cancelling out**: If LFO is bipolar (-1..1), the negative half drives cutoff to `0.75 - 0.5 = 0.25` which should be audible. But some LFO polarities could reduce effective modulation.

### Risk 3: Duplicate modulation functions
`applyModulation(SubtractiveSynthParams&, ...)` in DeviceChain.cpp line 106 and `applySubtractiveModulation(...)` in SubtractiveSynth.cpp line 94 are independent implementations. They MUST be kept in sync. A bug in one but not the other would be invisible because only the SubtractiveSynth.cpp version is used during per-frame rendering.

### Risk 4: `std::get_if` silent failure
If `DeviceVariantParams` somehow holds a wrong type (e.g., it was default-constructed as `OscillatorParams` instead of `SubtractiveSynthParams`), `applyAutomationValue`/`applyModulation` silently no-op. This would cause the observed symptoms. Check `buildPlaybackNode` in `SubtractiveSynthDeviceType.cpp` line 300-308 — it correctly sets `out.params = params` where `params` is from `instance.toPlaybackParams()` which returns `SubtractiveSynthParams`. However, if there's a path where `std::get<SubtractiveSynthParams>` fails (e.g., variant was replaced elsewhere), the silent failure would match the symptoms.

## Summary

| Hypothesis | Likelihood | Evidence |
|-----------|-----------|----------|
| paramIdFromString maps to wrong enum | **LOW** | "filterCutoff" → FilterCutoff=0 correctly |
| applyAutomationValue writes wrong field | **LOW** | Line 479: `p->filterCutoff = value` |
| applyModulation writes wrong field | **LOW** | Line 108: `p.filterCutoff = clamp(...)` |
| amount value is near-zero from UI | **MEDIUM-HIGH** | Most likely cause — investigate P3 first |
| std::get_if silently fails | **MEDIUM** | Check DeviceVariantParams type at runtime |
| normalizedCutoffToHz response curve | **MEDIUM** | Saw-wave "stabs" symptom suggests cutoff 0 = silence |
| LFO polarity mismatch | **LOW-MEDIUM** | Could reduce effective modulation |