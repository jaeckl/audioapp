# Open Device Nesting — Feature Brief

> **STATUS: CONTRACT READY**  
> **Feature folder:** `docs/features/open-device-nesting/`

## User-Visible Goal (Wow Moment)

A PO can demo on device:

1. Insert a **Device Chain** on a track.
2. Expand it → insert another **Device Chain** (or LR/MS split, MB split, Spectral Loud) inside it.
3. Nest again (chain⊂chain⊂chain, or container inside spectral PRE / band / POST, MB band, LR/MS branch, drum pad, synth audio FX).
4. Expand any nested container → add FX → hear audio → see live meters → automate / modulate a nested param.
5. Hit a soft capacity limit → **clear structured error** (toast / bridge error), never silent no-op.

**Product decision (locked):** ANY device type may nest in ANY device sub-strip. No type-based nesting restrictions. Soft capacity limits with clear errors OK; silent failure not OK.

## Non-Goals

- Redesign device picker UX / new container types
- Raise hard realtime buffer sizes without measured need (limits stay soft + reported)
- Graph editor / free-form node routing beyond existing container semantics
- Changing per-device DSP algorithms
- IAP / unlock gating
- Horizontal “rewrite all device UI” — only nesting paths

## Problem Statement (Research — Locked Blockers)

| # | Blocker | Symptom today |
|---|---------|---------------|
| B1 | Virtual strips only for top-level `track.visibleDevices` | Nested containers: card only; expand / PRE / POST dead |
| B2 | Nested meters dead | No `meterSlot` on nested playback; sub-`processChain` drops `deviceMeters` ctx; Flutter `MeterSubscription` ignores nest + expanded strip widths |
| B3 | `findDeviceLocked` = 1 generation | chain⊂chain commands fail at depth ≥ 2 |
| B4 | Auto/mod target scan 1-level | Nested + spectral targets often missing |
| B5 | Shared `DeviceChainScratch` re-entrancy | Nested `processChain` stomps `perFrameGain`/`Pan` + `tempStereo` dry buffers |

### Major capacity / policy issues

| Issue | Current behavior | Contract target |
|-------|------------------|-----------------|
| Ring leases `kMaxTimeBasedEffects = 6` | Silent `ensureBuffers` fail → mute FX | Soft limit + structured error / rebuild reject |
| Subgraph schedule `kMaxCompiledDeviceSubgraphSteps = 512` | `overflow` → container bypass | Soft limit + structured error; no silent bypass |
| Branch `devices[8]` / pad `devices[4]` | Hard cap, often empty return | Soft cap + `NestingError` on add |
| Layout / minimap | Top-level only | Recursive widths for expanded hosts |
| Type reject gates | Engine + Flutter drop containers | **Remove** all type-based nesting rejects |

## Policy Gates to Remove

| Location | Symbol / pattern |
|----------|------------------|
| `ProjectEngine` | `addDeviceTo*` type rejects (`deviceType == kChain`, `isSplitType`, etc.) |
| `*DeviceType` playback builders | `isForbiddenNestedType` (Spectral / MB / Split) |
| `ProjectJson` | Drop / skip filters that strip nested containers on load |
| Flutter | `_splitNestingRejectedTypes`, `_mbNestingRejectedTypes`, `_slNestingRejectedTypes`, siblings |

## Definition of Done

- [ ] Any known device type insertable into any sub-strip (chain, split branch, MB band, spectral PRE/band/POST, drum pad, synth note/audio FX) including container-in-container at arbitrary depth until soft capacity.
- [ ] Nested container expand + virtual sub-strip chrome works at every depth.
- [ ] Nested live meters work for dynamics / analysis / splits that publish meters.
- [ ] `findDeviceLocked` + set-param / add / remove / move work at depth ≥ 2.
- [ ] Automation + modulation can target nested (incl. spectral) params.
- [ ] Nested audio correct under re-entrant `processChain` (no gain/pan/dry stomp).
- [ ] Capacity / schedule / ring-lease failures return structured errors; no silent empty string / silent bypass for user-initiated adds.
- [ ] Deep-nest smoke tests + flipped “reject containers” tests green.
- [ ] Deployed APK on device ZY32MCWDJ6 for PO demo.

## Ship Order (Locked)

1. Recursive topology compiler/validator + structured errors  
2. Recursive `findDevice` + auto/mod target map  
3. Recursive meter slots + forward ctx + Flutter subscribe/layout  
4. Scratch re-entrancy fix  
5. Recursive virtual strips + expand/chrome wiring  
6. Drop reject filters  
7. Flip tests + deep nest smokes  

## Companion Docs

| Doc | Role |
|-----|------|
| `01-architecture.md` | Decisions, boundaries, error model |
| `02-canonical-vocabulary.md` | Binding names |
| `03-api-contracts.md` | Public APIs / bridge errors |
| `04-data-contracts.md` | DTOs / error codes / limits |
| `05-file-ownership.md` | WP file ownership |
| `06-vertical-work-packages.md` | Executable WPs |
| `07-test-contract.md` | Required tests |
| `08-integration-plan.md` | Merge order + risks |
| `09-ux-flow-contract.md` | *(layout-contract-designer — after this contract)* |

## Existing Code to Reuse

- `DeviceSubgraphTree` / `compileDeviceSubgraphTree` / `CompiledDeviceSubgraphSchedule`
- `DeviceChainOrchestrator::processChain` + container processors (`ChainProcessor`, `*Split*Processor`, `SpectralLoudSplitProcessor`, `DrumMachineProcessor`)
- `DeviceChainScratch` / `DeviceChainScratchArena`
- Flutter virtual strip parts (`device_chain_row_private_*_virtual_*`)
- `MeterSubscription`, `DeviceChainLayout`, `VirtualStripHostSnapshot`
- `collectDeviceTreeIds` (extend pattern for recursive walk)

## Out of Scope Capacity Raises

Raising `kMaxTimeBasedEffects`, `kMaxCompiledDeviceSubgraphSteps`, branch `8`, or pad `4` is **allowed only** when validator proves need and memory budget is accepted. Default: keep numbers, surface errors.
