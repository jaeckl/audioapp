# Vertical Work Packages: Open Device Nesting

## Worker instructions (every WP)

Implementation agents must:

- obey canonical names (`02-canonical-vocabulary.md`)
- stay within assigned files (`05-file-ownership.md`)
- not invent public APIs
- not rename concepts
- not redesign architecture
- not touch files owned by another package
- stop and report missing contract items instead of guessing

---

## WP-01 — Topology validator + structured errors

**Behavior:** Control-thread can estimate nest capacity (branch, pad, track flatten, subgraph steps, ring leases) and return `NestingError` instead of silent failure. Stubs `DeviceTreeWalk` for later WPs.

**Assigned files**

- `engine_juce/include/audioapp/devices/NestingError.hpp` *(new)*
- `engine_juce/include/audioapp/devices/DeviceNestingValidator.hpp` *(new)*
- `engine_juce/src/devices/DeviceNestingValidator.cpp` *(new)*
- `engine_juce/include/audioapp/devices/DeviceTreeWalk.hpp` *(new stub)*
- `engine_juce/src/devices/DeviceTreeWalk.cpp` *(new stub OK)*
- `engine_juce/include/audioapp/devices/` capacity constant header if needed
- Minimal bridge mapping hook for one add path (prove PlatformException shape)
- Tests: `engine_juce/tests/device_nesting_validator_test.cpp` *(new)*

**Forbidden files:** Flutter UI, processor DSP algorithms, deleting reject filters (WP-06).

**Canonical names:** `NestingError`, `NestingErrorCode`, `DeviceNestingValidator`, `NestingCapacityLimits`, `DeviceTreeWalk`, `kMaxDevicesPerNestBranch`.

**Dependencies:** None. **Provides to:** all.

**Acceptance**

- [ ] Validator rejects over-cap insert with correct code
- [ ] Ring-lease and subgraph-step estimates covered by unit tests
- [ ] Bridge error shape documented + one wired path
- [ ] No type-based rejection in validator (types always OK if known)

**Tests:** unit tests for each `NestingErrorCode` path (except UnknownParent — WP-02).

**Manual:** N/A (engine).

**Integration risk:** Medium — estimate must match real `ensureBuffers` / compile counts.

**Parallel:** **Parallel-safe** (foundation).

---

## WP-02 — Recursive findDevice + auto/mod targets

**Behavior:** `findDeviceLocked` finds devices at any nest depth. Automation + modulation target maps include nested (incl. spectral PRE/band/POST) params. Depth≥2 `add`/`setParameter`/`remove` work once parent found.

**Assigned files**

- `DeviceTreeWalk.*` (complete walk)
- `ProjectEngine.cpp` / `.hpp` — `findDeviceLocked`, target scan helpers, any 1-level loops that register auto/mod targets
- Related modulation/automation registration call sites inside ProjectEngine only

**Forbidden files:** Flutter reject lists, scratch, meter UI.

**Canonical names:** `DeviceTreeWalk`, `findDeviceLocked`, `collectDeviceTreeIds`.

**Dependencies:** WP-01 stubs. **Provides to:** WP-03, WP-06, WP-07.

**Acceptance**

- [ ] chain⊂chain⊂device: `setDeviceParameter` succeeds
- [ ] Modulation edge to nested device resolves
- [ ] Automation clip target list includes nested spectral child

**Tests:** engine test building depth-3 chain; find + set param; mod edge apply.

**Manual:** automate nested FX on device.

**Integration risk:** High if any 1-level walk left behind — grep for container child loops.

**Parallel:** **Sequential after WP-01 stubs**.

---

## WP-03 — Recursive meters (engine + Flutter)

**Behavior:** Nested publishers get `meterSlot`. Nested `processChain` forwards `deviceMeters` / subscription flags. Flutter `MeterSubscription` + layout include nested/expanded strip widths.

**Assigned files**

- Playback rebuild meter assignment in `ProjectEngine.cpp` (shared — coordinate)
- Container processors: Chain/Split/MB/Spectral/DrumMachine — ctx forward only
- `ProcessContext.hpp` / orchestrator context if needed
- `app_flutter/lib/features/device_strip/meter_subscription.dart`
- Possibly `daw_shell_private_*_update_meter_subscriptions.dart`

**Forbidden files:** Reject-filter deletion, scratch frame impl (call WP-04), virtual strip chrome redesign beyond meter width hooks.

**Canonical names:** `meterSlot`, `DeviceMeterAtomic`, `MeterSubscription`, `ProcessContext::deviceMeters`.

**Dependencies:** WP-01 stubs; ideally WP-02 for deep ids. **Provides to:** WP-07.

**Acceptance**

- [ ] Nested compressor GR meter updates in UI
- [ ] Nested analysis device receives subscription when scrolled into view inside expanded host
- [ ] Sub-`processChain` does not pass null `deviceMeters` when parent has meters

**Tests:** processor test asserting meter atomics written for nested node; Flutter unit for recursive `visibleMeterDeviceIds`.

**Manual:** expand nested chain, watch GR.

**Integration risk:** Medium — expansion set plumbing.

**Parallel:** **Parallel-safe after WP-01 stubs** (engine meters ∥ Flutter subscription if API stable).

---

## WP-04 — Scratch re-entrancy

**Behavior:** Nested `processChain` cannot stomp outer `perFrameGain`/`Pan`/`tempStereo*`. Introduce `DeviceChainScratchFrame` / guard; wrap all nested call sites.

**Assigned files**

- `DeviceChainScratch.hpp` (+ `.cpp` if needed)
- Nested call sites in container processors + orchestrator
- Tests: nested chain gain automation correctness

**Forbidden files:** Flutter, ProjectJson, reject filters.

**Canonical names:** `DeviceChainScratchFrame`, `DeviceChainScratchGuard` (if used), `DeviceChainScratch`.

**Dependencies:** None. **Provides to:** WP-07 audio correctness.

**Acceptance**

- [ ] Outer chain gain automation stable while inner chain processes
- [ ] No heap in guard
- [ ] All nested `processChain` sites wrapped (checklist in PR)

**Tests:** renderOffline nested topology with outer per-frame gain; compare vs non-nested baseline expectation.

**Manual:** nested FX while automating parent chain mix/gain.

**Integration risk:** High (audio correctness) — isolate with A/B render tests.

**Parallel:** **Parallel-safe**.

---

## WP-05 — Recursive virtual strips + expand/chrome

**Behavior:** Expanding a nested container shows the same virtual sub-strip chrome (PRE/POST/bands/branches/pads/FX) as top-level. Layout + minimap account for nested expanded widths. Add-from-substrip calls work at any depth (capacity via NestingError only).

**Assigned files**

- `device_chain_row_private_device_chain_row_state*.dart` (+ virtual_* parts)
- `device_chain_layout.dart`
- `device_chain_minimap_*` as needed
- `project_snapshot.dart` helpers if required
- `device_strip_chrome.dart` only if expand affordance gated on top-level

**Forbidden files:** Engine reject deletion (WP-06), validator C++.

**Canonical names:** `VirtualStripHostSnapshot`, virtual strip part methods, `DeviceChainLayout`.

**Dependencies:** WP-01 stubs (error display optional); WP-02 for deep commands. **Provides to:** WP-06, WP-07.

**Acceptance**

- [x] Nested chain expand shows child strip + add button
- [x] Nested spectral shows PRE / bands / POST
- [x] Layout scroll width includes expanded nested hosts

**Tests:** Flutter widget tests with nested snapshots + expand.

**Manual:** PO wow path: nest containers freely; capacity failures surface as NestingError snackbar.

**Integration risk:** Medium — shared row state file size; keep SRP splits if >300 LOC growth.

**Parallel:** **Parallel-safe after WP-01 stubs**; **before WP-06** on same dart reject files.

---

## WP-06 — Drop type reject filters

**Behavior:** Remove all type-based nesting restrictions. Inserts go through `DeviceNestingValidator` only. Flutter picker no longer early-returns on container types. ProjectJson keeps nested containers.

**Assigned files**

- `ProjectEngine.cpp` — all `addDeviceTo*` type rejects → validator
- `ProjectJson.cpp` — drop filters
- `SpectralLoudSplitDeviceType.cpp`, `MultibandSplitDeviceType.cpp`, split device types — delete `isForbiddenNestedType`
- Flutter `_*NestingRejectedTypes` deletions + ensure errors surfaced
- Bridge add wrappers if they swallow errors

**Forbidden files:** Inventing new reject lists; raising caps without validator update.

**Canonical names:** delete `isForbiddenNestedType`; use `DeviceNestingValidator`, `NestingError`.

**Dependencies:** WP-01 (validator), WP-05 (UI can show nested containers). **Provides to:** WP-07.

**Acceptance**

- [x] Add `device_chain` into split branch succeeds (under caps)
- [x] Add spectral into chain into MB band succeeds
- [x] Over-cap still fails with NestingError
- [x] Load project with deep nest round-trips

**Tests:** flip existing “reject containers” tests; JSON round-trip deep nest.

**Manual:** full wow moment on device.

**Integration risk:** High — do last before smokes.

**Parallel:** **Sequential dependency** (after WP-01 + WP-05).

---

## WP-07 — Flip tests + deep-nest smokes

**Behavior:** Test suite encodes open nesting. Deep-nest smokes (engine + Flutter). Deploy APK for PO.

**Assigned files**

- Engine tests under `engine_juce/tests/` (processor_graph, nesting, spectral, routing as needed)
- Flutter tests that asserted nesting rejection
- Deploy via `.\tools\flutter_deploy.ps1` (not a file edit)

**Forbidden files:** New feature scope beyond fixing tests / tiny glue.

**Dependencies:** WP-01…WP-06. **Provides to:** DoD.

**Acceptance**

- [x] All flipped tests green
- [x] Depth-3+ smoke (S1/S5/S6 + synth FX cap) green
- [x] APK installed on ZY32MCWDJ6

**Parallel:** **Integration-only**.

---

## Parallelization summary

| Class | WPs |
|-------|-----|
| Parallel-safe | WP-01, WP-04 |
| Parallel-safe after WP-01 stubs | WP-03 (split engine/Flutter), WP-05 |
| Sequential | WP-02 after WP-01; WP-06 after WP-01+WP-05; WP-03 meter assign touches `ProjectEngine` after WP-02 preferred |
| Integration-only | WP-07 |

### Recommended implementation order

1. WP-01  
2. WP-02 ∥ WP-04 *(parallel)*  
3. WP-03 ∥ WP-05 *(parallel after stubs; careful `ProjectEngine`)*  
4. WP-06  
5. WP-07 + deploy  
