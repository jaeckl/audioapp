# Architecture: Open Device Nesting

## Layers

```
Flutter device strip / virtual sub-strips / meters
  → MethodChannel addDeviceTo* / setDeviceParameter / setMeterSubscriptions
Native control thread (ProjectEngine mutex)
  → DeviceNestingValidator → recursive DeviceSlot tree mutate
  → rebuildTrackPlaybackLocked → recursive playback + meterSlot assign
Audio thread
  → DeviceChainOrchestrator::processChain (re-entrant scratch frames)
  → Container processors → nested processChain with forwarded ProcessContext
```

## Architecture Decision

**AD-1 Open topology.** Device nesting is type-unrestricted. Containers may own any `DeviceSlot` type, including other containers, at any depth.

**AD-2 Soft capacity, hard honesty.** Soft limits (branch count, pad count, schedule steps, ring leases, track flatten) remain. Violations produce `NestingError` on control-thread mutations. Audio thread never allocates; if a live graph somehow exceeds a lease, processor must no-op that effect **and** the prior rebuild should have already rejected/reported — user-facing path is control-thread validation.

**AD-3 Single recursive walker.** One canonical recursive visitor owns: find-by-id, collect ids, auto/mod target enumeration, meter slot assignment, JSON child walk, subgraph tree build. No 1-generation special cases.

**AD-4 Scratch stack frames.** Nested `processChain` pushes/pops a `DeviceChainScratchFrame` (or equivalent) for `perFrameGain`, `perFramePan`, `tempStereoL/R` (and any other buffers nested chains overwrite). Ring arena stays track-scoped leases; nesting does not share dry buffers across depths.

**AD-5 Virtual strips are topology-driven.** Any expanded `VirtualStripHostSnapshot` (any depth) emits the same sub-strip chrome as top-level hosts. Layout width and meter viewport math recurse into expanded hosts.

**AD-6 Drop type reject before demo.** Reject-filter removal (WP-06) lands only after validator + recursive find + UI expand (WP-01/02/05) exist so open nesting cannot create silent failures.

## Module Boundaries

| Module | Responsibility | Not responsible for |
|--------|----------------|---------------------|
| `DeviceNestingValidator` | Pre-mutate capacity + schedule estimate; emit `NestingError` | DSP, UI |
| `DeviceTreeWalk` (or extend `collectDeviceTreeIds` / `findDeviceLocked`) | Recursive DeviceSlot traversal | Playback DSP |
| `DeviceSubgraph` | Recursive tree compile; overflow → error signal to control | Mutating project |
| Meter assignment in playback rebuild | Assign unique `meterSlot` for every publishing nested node; forward `deviceMeters` in sub-ctx | Flutter layout |
| `DeviceChainScratch` frame stack | Re-entrancy for nested processChain | Ring lease policy messaging |
| Flutter virtual strip parts | Expand / add / layout / meters at any depth | Engine validation rules |
| Flutter reject-list removal | Delete `_*NestingRejectedTypes` | Capacity toasts (consume bridge error) |

## Threading / Async Boundaries

| Thread | Allowed | Forbidden |
|--------|---------|-----------|
| Control (`ProjectEngine` write lock) | Mutate tree, validate, rebuild playback, assign meter slots, return errors to bridge | Audio buffer writes |
| Audio | `processChain`, push/pop scratch frames, use assigned `meterSlot`, read immutable playback | Heap alloc, JSON, tree walk by string id, raise NestingError |
| UI isolate | Expand state, subscribe meters by recursive layout, show NestingError | Assuming silent empty add succeeded |

## Ownership Boundaries

- **ProjectEngine** owns DeviceSlot tree + `findDeviceLocked` + add/remove APIs.
- **DeviceType builders** must recursively build nested playback (no `isForbiddenNestedType` skip).
- **Container processors** own nested `processChain` calls; must forward meter ctx + use scratch frames.
- **Flutter strip** owns expansion UI; engine owns truth of nest contents via snapshot.

## Error Model

Canonical type: `NestingError` (see `04-data-contracts.md`).

| Code | When |
|------|------|
| `branch_device_cap` | Branch / chain / FX list ≥ soft max (8) |
| `pad_device_cap` | Pad ≥ `DrumMachineModel::kMaxDevicesPerPad` (4) |
| `track_device_cap` | Flattened playback would exceed `kMaxDevicesPerTrack` |
| `subgraph_step_overflow` | Compiled schedule would set `overflow` |
| `ring_lease_exhausted` | Time-based / spectral / MB buffer leases > `kMaxTimeBasedEffects` |
| `unknown_parent` | Parent id not found (incl. deep nest before WP-02 fix) |
| `unknown_type` | `deviceRegistry_.isKnownType` false |

Bridge: MethodChannel result must not be empty-success. Prefer throwing `PlatformException` with `code = NestingError.code` and `message` human-readable, or structured map `{ ok: false, error: {...} }` — **pick one** in WP-01 stub and keep consistent (see `03-api-contracts.md`). Silent `return {}` / early `return` in Flutter add handlers is forbidden after WP-06.

## Persistence Model

- `ProjectJson` must round-trip nested containers at any depth (no drop filters).
- Soft caps still apply on load: prefer **truncate with log + NestingError diagnostic** only if load would exceed hard array sizes; prefer reject whole project load section over silent type drops. Exact load policy: keep children until soft cap; emit warning list in load diagnostics (WP-01).

## UI / State Sync

1. Mutate → `rebuildTrackPlaybackLocked` → project snapshot to Flutter.
2. Expansion is UI-local (which host ids expanded) but child lists always from snapshot.
3. Meter ids from recursive `MeterSubscription.visibleMeterDeviceIds` including expanded nested strip widths.
4. NestingError → snackbar / dialog; do not clear expansion.

## Existing Code to Reuse (Do Not Fork)

- `buildDeviceSubgraphTree` / `compileDeviceSubgraphTree`
- `collectDeviceTreeIds` (make recursive into nested containers — today already walks one level of each container type; extend to depth via shared walker used by find)
- Virtual strip host pattern + `DeviceCapabilities.virtualStripHosts`
- `ProcessContext.deviceMeters` / `meterSlot` on `DeviceNodePlayback`

## Acceptance Criteria (Feature-Level)

1. Depth-3 chain⊂chain⊂chain: add compressor at leaf, set param, hear effect.
2. Spectral PRE contains MB split containing chain containing delay: audio + expand UI.
3. Nested compressor GR meter moves in UI.
4. Automate nested filter cutoff; modulate nested gain.
5. 9th device on a branch → NestingError, branch still has 8.
6. Enough nested delays to exceed ring leases → NestingError on add (not silent mute).
7. No type reject: picker can insert `device_chain` into split branch.

## Work Package Map (IDs)

| ID | Slice | Parallel class |
|----|-------|----------------|
| **WP-01** | Topology validator + NestingError + capacity estimates | Parallel-safe (foundation) |
| **WP-02** | Recursive findDevice + auto/mod target map | Sequential after WP-01 stubs |
| **WP-03** | Recursive meter slots + ctx forward + Flutter subscribe/layout | Parallel-safe after WP-01 stubs; integrate with WP-02 ids |
| **WP-04** | Scratch re-entrancy frames | Parallel-safe |
| **WP-05** | Recursive virtual strips + expand/chrome + layout/minimap | Parallel-safe after WP-01 stubs; before/with WP-06 |
| **WP-06** | Drop all type reject filters (engine + JSON + Flutter) | Sequential after WP-01 + WP-05 |
| **WP-07** | Flip tests + deep-nest smokes + device verify | Integration-only |

Detail: `06-vertical-work-packages.md`.
