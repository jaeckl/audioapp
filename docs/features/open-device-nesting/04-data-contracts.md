# Data Contracts: Open Device Nesting

## Soft capacity defaults (binding until measured raise)

| Limit | Canonical name | Default | Applies to |
|-------|----------------|---------|------------|
| Nest branch / FX list | `kMaxDevicesPerNestBranch` | `8` | Chain children, split branch, MB band, spectral lists, synth audio/note FX |
| Drum pad | `DrumMachineModel::kMaxDevicesPerPad` | `4` | Per pad |
| Track flatten | `kMaxDevicesPerTrack` | `24` | Playback snapshot device array |
| Subgraph steps | `kMaxCompiledDeviceSubgraphSteps` | `512` | `CompiledDeviceSubgraphSchedule` |
| Ring leases | `DeviceChainScratchArena::kMaxTimeBasedEffects` | `6` | Concurrent delay/reverb/chorus/phaser/stutter/spectral/MB buffer pairs |

## `NestingCapacityLimits`

```cpp
struct NestingCapacityLimits {
  int maxDevicesPerNestBranch = 8;
  int maxDevicesPerPad = 4;
  int maxDevicesPerTrack = 24;
  int maxCompiledSubgraphSteps = 512;
  int maxRingLeases = 6;
};
```

Defaults must match table. Tests may construct tighter limits.

## `NestingErrorCode` ↔ bridge string

| Enum | Bridge `code` | User-facing message seed |
|------|---------------|--------------------------|
| `None` | *(success)* | — |
| `BranchDeviceCap` | `branch_device_cap` | "This strip is full (max {limit} devices)." |
| `PadDeviceCap` | `pad_device_cap` | "This drum pad is full (max {limit} devices)." |
| `TrackDeviceCap` | `track_device_cap` | "Track device limit reached (max {limit})." |
| `SubgraphStepOverflow` | `subgraph_step_overflow` | "Device graph too deep/complex for this track." |
| `RingLeaseExhausted` | `ring_lease_exhausted` | "Too many time-based/buffer effects on this track (max {limit})." |
| `UnknownParent` | `unknown_parent` | "Parent device not found." |
| `UnknownType` | `unknown_type` | "Unknown device type." |

## Device tree (unchanged shapes, open content)

Existing models keep field names:

| Container | Child fields |
|-----------|--------------|
| `ChainModel` | `devices` |
| `SplitModel` | `branch0`, `branch1` |
| `MultibandSplitModel` | `bands[]` |
| `SpectralLoudSplitModel` | `preFxDevices`, `bands[]`, `postFxDevices` |
| `DrumMachineModel` | `pads[].devices` |
| `DeviceSlot` (instruments) | `noteFxDevices`, `audioFxDevices` |

**Content rule:** each child vector may hold **any** known `typeId`, including containers. No schema flag for “allowed types”.

## Playback nesting

| Field | Rule |
|-------|------|
| `SplitBranchPlayback::devices[8]` / `deviceCount` | Still max 8; fill all allowed types; do not skip containers |
| Nested `DeviceNodePlayback` | Built recursively via registry; `meterSlot ≥ 0` if publisher |
| `CompiledDeviceSubgraphSchedule::overflow` | Must not silently bypass after WP-01: control path treats as `SubgraphStepOverflow` |

## Project JSON

- Nested devices serialize under existing container keys (same as today for 1-level).
- Load must recurse without dropping `device_chain` / splits / spectral / MB.
- On cap during load: stop appending further siblings; record diagnostic (prefer not to invent new project schema version for v1).

## Flutter snapshot

- Nested lists already exist on split/chain/spectral/drum/synth snapshots — keep field names.
- `visibleDevices` remains **top-level only**.
- Expansion: UI `Set<String> expandedDeviceIds` (local); not persisted unless already persisted elsewhere (non-goal to add persistence).

## Ring lease counting (validator estimate)

Count processors that call `ringBufferArena.allocate` in the track tree, including nested:

- Delay, Reverb, Chorus, Phaser, Stutter (and any other `ensureBuffers` arena users)
- Multiband / Spectral may take **multiple** leases per instance — estimator must use same count as `ensureBuffers` (audit in WP-01).

If estimate > `maxRingLeases` → `RingLeaseExhausted` **before** insert commits.
