# UX Flow Contract: Open Device Nesting

> **STATUS: READY FOR IMPLEMENTATION**  
> Grounded in: `00-feature-brief.md`, `01-architecture.md`, `02–04` contracts, `06-vertical-work-packages.md`  
> Product lock: ANY device type in ANY sub-strip (incl. chain⊂chain). Soft capacity → `NestingError` in UI (never silent).

## UX Summary

- **User Goal**: Nest containers and FX at any depth inside device sub-strips; expand nested hosts; hear audio; see live meters; get clear capacity/depth errors.
- **Main Flow**: Insert container on track → expand virtual sub-strip chrome → insert another container or FX inside → repeat → adjust nested params → watch nested meters.
- **Secondary Flows**:
  - Collapse nested host chrome (where expand toggles exist).
  - Add until soft cap → snackbar with `NestingError` message; strip unchanged.
  - Automate / modulate nested params (same long-press / link affordances as top-level).
- **Non-Goals** (from feature brief):
  - Redesign device picker or new container types
  - Graph editor / free-form routing
  - Persist expansion state across sessions (UI-local only)
  - Raise soft caps without validator proof
  - New per-device LFO/modulator chrome

## Existing UI Pattern Inventory


| Existing file/component | Purpose | Relevant pattern to reuse | Notes |
| ----------------------- | ------- | ------------------------- | ----- |
| `device_chain_row_private_device_chain_row_state.dart` | Top-level strip row; expand maps; meter report | Expand maps (`_splitBranchExpanded`, `_mbBandExpanded`, `_slBandExpanded`, `_synth*FxExpanded`); post-frame meter report | Must recurse into nested hosts |
| `device_chain_row_private_device_chain_row_state_virtual_*.dart` | Virtual sub-strips (chain, split, MB, spectral PRE/band/POST, pad, note/audio FX) | Bracket + rotated title + child `DeviceStripSlot` row + `DeviceInsertSlot` | Today: children not recursive hosts |
| `device_chain_row_private_virtual_chain_bracket_painter.dart` | Bracket painter + cut pillars (`_BracketInterruptedStrip`) | Keep | Parent bracket visually cut where child starts/ends |
| `device_strip_chrome.dart` / PRE·POST panels | Spectral PRE FX / POST FX toggles; synth note/audio FX toggles | Chrome toggles drive which virtual strip appears | Nested spectral must expose same PRE/POST/band toggles |
| `split_device_panel_branch_row.dart` / `multiband_split_panel_band_column.dart` / `spectral_loud_split_panel_band_row.dart` | Branch/band expand affordances on host card | `active` expand + toggle callback | Nested host cards use same affordances |
| `meter_subscription.dart` | Viewport meter device ids | `publishesLiveMeters` + scroll viewport walk | Add recursive walk + `expandedDeviceIds` (API contract) |
| `device_chain_layout.dart` | Slot + chain scroll widths | `slotWidthFor` / total width | Must include nested expanded host widths |
| `showDevicePickerSheet` + `DeviceInsertSlot` | Add device into sub-strip | Picker → bridge `addDeviceTo*` | After WP-06: no `_*NestingRejectedTypes` early return |
| `device_strip_slot_private_*_on_bridge_call.dart` | Bridge call + `SnackBar` on error | Catch → `ScaffoldMessenger` snackbar | Extend for `PlatformException` `NestingError` codes |
| `DeviceCapabilities.virtualStripHosts` | Which types host virtual strips | Topology-driven chrome | Nested instances of same types are hosts too |

## Reusable Components


| UI need | Existing component/pattern | Source file | Reuse as-is? | Needed adaptation |
| ------- | -------------------------- | ----------- | ------------ | ----------------- |
| Nested chain children strip | `_virtualDeviceChain` | `…_virtual_device_chain.dart` | Pattern yes | Recurse: if child is container host, emit its virtual chrome when expanded |
| Nested split branch strip | `_virtualSplitBranch` | `…_virtual_split_branch.dart` | Pattern yes | Delete `_splitNestingRejectedTypes`; surface `NestingError`; recurse |
| Nested MB band strip | `_virtualMultibandBand` | `…_virtual_multiband_band.dart` | Pattern yes | Delete `_mbNestingRejectedTypes`; recurse |
| Nested spectral PRE/band/POST | `_virtualSpectralLoud*` | `…_virtual_spectral_loud.dart` | Pattern yes | Delete `_slNestingRejectedTypes`; recurse; PRE/POST toggles work when spectral itself is nested |
| Nested pad / note / audio FX | `_virtualPadChain` / `_virtualNoteFxChain` / `_virtualAudioFxChain` | matching `virtual_*` parts | Pattern yes | Recurse; pad soft cap → `pad_device_cap` snackbar |
| Expand toggles on host card | Split/MB/spectral band rows; PRE/POST chrome | panel + chrome files | Yes | Wire expand keys by **device id** at any depth (maps already keyed by id) |
| Meter subscribe | `MeterSubscription.visibleMeterDeviceIds` | `meter_subscription.dart` | No | Recursive widths + optional `expandedDeviceIds` |
| Capacity / depth error | SnackBar via bridge catch | `…_on_bridge_call.dart` + virtual add handlers | Pattern yes | Map `PlatformException.code` → seed messages from `04-data-contracts.md` |
| Insert affordance | `DeviceInsertSlot` | existing | Yes | Hide/disable when at soft cap **only after** failed add is optional; prefer attempt + error (validator is source of truth) |

## Forbidden Inventions

- Do **not** invent a new nesting toolbar, nest-depth badge, or “nest mode”.
- Do **not** invent tabs for nested chrome — reuse PRE/POST/band/branch toggles.
- Do **not** invent a modal for capacity errors — use existing snackbar pattern (dialog only if snackbar already used elsewhere for same class of error; default = snackbar).
- Do **not** invent new reject lists or type filters after WP-06.
- Do **not** invent per-device LFOs/modulators for nested devices.
- Do **not** invent Material dropdowns for filter mode on nested devices (unchanged device panels).
- Do **not** invent alternate error type names (`NestError`, etc.) — only `NestingError` / bridge `code`.
- Do **not** invent persisted expand state schema.
- Do **not** redesign picker categories for “containers only”.
- Do **not** silent `return` on rejected picker types or empty bridge success.

---

## Screen Map


| Screen/Area | Purpose | Entry point | Exit / Next action |
|-------------|---------|-------------|--------------------|
| Track device strip (`DeviceChainRow`) | Horizontal chain of top-level devices + virtual sub-strips | Project / track focus | Scroll; expand hosts; insert |
| Virtual sub-strip (any depth) | Accent bracket chrome (corner ticks); strip-background cut pillars interrupt parent bracket where child strip starts/ends; child opens its own bracket; same card size as top-level | Expand toggle on host **or** always-on for `device_chain` | Add via `DeviceInsertSlot`; expand nested host inside |
| Nested host card (`DeviceStripSlot`) | Same card chrome as top-level for that type | Child of a virtual strip | Toggle its own PRE/POST/bands/branches → nested virtual strip appears after it |
| Device picker sheet | Choose any known type (post WP-06) | `DeviceInsertSlot` / separator insert | Confirm → `addDeviceTo*`; cancel → no change |
| NestingError snackbar | Surface capacity/depth/parent/type failures | Failed `addDeviceTo*` / related mutate | Auto-dismiss; expansion unchanged |

---

## Screen/Area Layout

### Top-level strip + recursive virtual chrome

```
┌─ DeviceChainRow (horizontal scroll) ─────────────────────────────────────────┐
│ [Chain₁]┌─ CHAIN ▸ child ┤ ░░ ┤┌─ CHAIN ▸ leaf ┐░ ┤ + ─┐ │                   │
│         └──── parent ────┘ cut └─ child bracket ┘cut └────┘                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Nested spectral (chrome when nested)

```
┌─ SpectralLoud (nested inside outer CHAIN strip) ─────────────────────────────┐
│ [Spectral card: band toggles + PRE FX + POST FX chrome]                      │
│   └─ if PRE on:   [ PRE ▸ devices… + ]                                       │
│   └─ if band i:   [ LOUD/… ▸ devices… + ]                                    │
│   └─ if POST on:  [ POST ▸ devices… + ]                                      │
│         └─ child may itself be container → recurse same chrome               │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Layout rules

| Rule | Binding |
|------|---------|
| Parent container | `DeviceChainRow` `ListView` (horizontal) |
| Region order | Host card → its virtual strip region(s) (same order as top-level today) → separator |
| Nested host order | Inside a virtual strip: child card → **that child’s** virtual strip region(s) if expanded → next sibling |
| Alignment | Bracket chrome + rotated title; devices match top-level size |
| Spacing | Strip-background cut pillars (`virtualStripCutWidth`) interrupt parent bracket around nested strips |
| Scroll | Single horizontal scroll of the track row; nested strips widen the scroll extent via `DeviceChainLayout` |
| Overflow | Horizontal scroll; do not wrap virtual strips to a second row |
| Fixed vs grow | Row height fixed by density; width grows with expanded nested hosts |
| Collapse | Collapse removes that host’s virtual region(s) from the row; child devices remain in snapshot |

---

## Widget Hierarchy

```
DeviceChainRow
├── DeviceStripSlot (top-level host)
│   └── (existing panel + chrome toggles: bands / PRE / POST / branches / pad chain)
├── VirtualStripRegion*          // existing _virtual* builders — any depth
│   ├── _VirtualChainBracketPainter
│   ├── RotatedBox title (CHAIN | PRE | POST | band | L/R | PAD | …)
│   ├── for child in region.devices:
│   │   ├── DeviceStripSlot (child — may be container)
│   │   └── VirtualStripRegion* (recursive when child host expanded)
│   └── DeviceInsertSlot (add)
└── DeviceChainSeparator
```

\*Not a new widget class name requirement — **behavior** contract: existing `_virtual*` builders (or a shared recursive helper extracted from them) must invoke the same host→region rules for nested container children. Prefer extract-by-responsibility if file growth >300 LOC (SRP rule); do not invent a new product concept.

---

## Data-to-UI Mapping


| UI element | Data source | Field name | Empty value | Error value |
|------------|-------------|------------|-------------|-------------|
| Top-level cards | `TrackSnapshot` | `visibleDevices` | Empty insert slot | — |
| Chain virtual children | `ChainDeviceSnapshot` | `devices` | Empty row + insert | — |
| Split branch children | `SplitDeviceSnapshot` | `branch0` / `branch1` | Empty + insert | — |
| MB band children | `MultibandSplitDeviceSnapshot` | band device lists | Empty + insert | — |
| Spectral PRE/band/POST | `SpectralLoudSplitDeviceSnapshot` | `preFxDevices` / band lists / `postFxDevices` | Empty + insert | — |
| Pad children | `DrumMachineDeviceSnapshot` | selected pad `devices` | Empty + insert | — |
| Synth note/audio FX | instrument `DeviceSnapshot` | `noteFxDevices` / `audioFxDevices` | Empty + insert | — |
| Expand PRE/POST/bands | UI-local maps keyed by `deviceId` | `_slBandExpanded`, `_synthNoteFxExpanded` (PRE), `_synthAudioFxExpanded` (POST), etc. | Collapsed = no virtual region | NestingError must **not** clear maps |
| Meter ids | `MeterSubscription.visibleMeterDeviceIds` | recursive device ids in viewport | `[]` | Stale ids OK until next report |
| Capacity error snackbar | `PlatformException` | `code`, `message`, `details.limit` / `attempted` | — | Show seed message from `04-data-contracts.md` |

---

## User Flows

### 1. Recursive expand / collapse nested container

- **Trigger**: User toggles branch/band/PRE/POST/pad-chain/note-FX/audio-FX on a host card that sits inside a virtual strip (or top-level).
- **Steps**:
  1. Toggle updates UI-local expand map for that `deviceId` (+ band/branch index if applicable).
  2. Row rebuilds: virtual strip region appears immediately after that host card (same relative order as top-level).
  3. If a child inside the region is itself a host and expanded, its virtual region appears after that child (recurse).
  4. Collapse removes only that host’s regions; ancestors stay expanded.
- **`device_chain` special case**: Keep today’s always-visible CHAIN virtual strip at every depth (no new collapse control unless one already exists for that type).
- **Feedback**: Bracket strip + children appear/disappear; scroll width updates; meter report reschedules.
- **Success**: Nested add buttons and child cards usable at depth ≥ 2.
- **Error**: None for expand itself (UI-local).

### 2. Nested chrome (PRE / POST / bands / branches)

- **Trigger**: Nested `spectral_loud_split`, `mb_split_*`, `lr_split` / `ms_split`, synth, or drum host is visible in a parent virtual strip.
- **Steps**:
  1. Host card shows the **same** chrome affordances as top-level (band rows, PRE FX / POST FX, branch expands, pad chain toggle).
  2. Activating chrome emits the matching virtual strip (`PRE`, `POST`, band label, branch label).
  3. Insert via that strip’s `DeviceInsertSlot` calls the same bridge methods as top-level (`addDeviceToSpectralLoudPreFx`, `…Band`, `…PostFx`, `addDeviceToMultibandBand`, `addDeviceToSplitBranch`, etc.) with the **nested host’s** `deviceId`.
- **Feedback**: Identical visual language (accent, bracket, rotated title).
- **Success**: PO can open PRE on a spectral that lives inside a chain.
- **Forbidden**: Different chrome layout for “nested vs top-level”.

### 3. Meter subscription when nested strips expand

- **Trigger**: Expand nested host and/or scroll so nested publishers enter viewport.
- **Steps**:
  1. After expand/collapse/scroll/layout, `_reportMeterSubscriptions` runs (existing post-frame path).
  2. `MeterSubscription.visibleMeterDeviceIds` walks top-level slots **and** expanded virtual regions recursively, advancing x by nested widths (`DeviceChainLayout`).
  3. Ids of nested publishers (`publishesLiveMeters`) that overlap viewport are reported via `onMeterSubscriptionsChanged`.
  4. Engine already assigned nested `meterSlot` (WP-03); UI binds `liveMetersListenable` to nested cards same as top-level.
- **Feedback**: Nested compressor GR / analysis / split meters animate when visible.
- **Success**: Deep-nest meters move without expanding only top-level hosts.
- **Error**: If engine lacks slot, meter stays flat — treat as WP-03 defect, not silent UI success.

### 4. Add device into nested sub-strip (open types)

- **Trigger**: Tap `DeviceInsertSlot` inside any virtual strip at any depth.
- **Steps**:
  1. `showDevicePickerSheet` — post WP-06: **all** known types allowed (incl. containers).
  2. Await bridge `addDeviceTo*` with parent id = host of that strip.
  3. On success: snapshot refresh; new child card appears in that strip.
  4. On `PlatformException`: show NestingError snackbar; **do not** mutate local tree; **do not** clear expansion.
- **Forbidden**: Early `return` on container types; ignore empty success.

### 5. NestingError surfacing (capacity / depth / parent / type)

- **Trigger**: Bridge throws `PlatformException` with `NestingError` code.
- **Steps**:
  1. Catch in virtual-strip add path and any shared bridge wrapper used by strip inserts.
  2. Show snackbar:
     - Prefer `exception.message` if non-empty.
     - Else map `code` → seed strings from `04-data-contracts.md` (interpolate `details.limit` when present).
  3. Duration ~3s (match existing modulation error snackbar).
  4. Leave expand maps and scroll position unchanged.
- **Codes that must surface** (not silent):

| Bridge `code` | Seed message (if message empty) |
|---------------|----------------------------------|
| `branch_device_cap` | This strip is full (max {limit} devices). |
| `pad_device_cap` | This drum pad is full (max {limit} devices). |
| `track_device_cap` | Track device limit reached (max {limit}). |
| `subgraph_step_overflow` | Device graph too deep/complex for this track. |
| `ring_lease_exhausted` | Too many time-based/buffer effects on this track (max {limit}). |
| `unknown_parent` | Parent device not found. |
| `unknown_type` | Unknown device type. |

- **Success**: 9th branch device → snackbar; branch still has 8.
- **Forbidden**: Swallow exception; toast-less no-op; fake success card.

### 6. Automate / modulate nested param (secondary)

- **Trigger**: Same knob long-press / automation link / mod assign as top-level, on a device card inside a nested strip.
- **Steps**: Unchanged UI; engine resolves targets via recursive `findDeviceLocked` / target map (WP-02).
- **Error**: Existing modulation snackbar path; no nesting-specific UI.

---

## Interaction Contract

```
Interaction: Expand nested spectral PRE
Trigger: Tap PRE FX chrome on nested spectral card
State: _synthNoteFxExpanded[spectralId] = true (existing map)
Command: none (UI-local)
Immediate UI: PRE virtual strip after card
Engine: none
Error: n/a
```

```
Interaction: Add chain inside chain
Trigger: DeviceInsertSlot in outer CHAIN strip → picker → device_chain
Command: addDeviceToChain(chainId: outerId, deviceType: device_chain)
Immediate UI: await; on success child Chain card + its CHAIN strip
Error: NestingError snackbar; no child added
```

```
Interaction: Add FX past branch soft cap
Trigger: Insert when branch already has kMaxDevicesPerNestBranch devices
Command: addDeviceTo* → DeviceNestingValidator fail
Immediate UI: none
Error: PlatformException code=branch_device_cap → snackbar
```

```
Interaction: Nested meter subscribe
Trigger: Expand nested host containing compressor; scroll into view
Command: setMeterSubscriptions (existing) with recursive visible ids
Immediate UI: GR meter moves on nested card
Error: flat meter → engine/UI subscribe bug (WP-03)
```

---

## State Contract


| Component | Empty | Loading | Ready | Editing / Expanded | Disabled | Error | Overflow |
|-----------|-------|---------|-------|--------------------|----------|-------|----------|
| Virtual strip region | Title + insert only | n/a (sync snapshot) | Child cards | Host expand true → region mounted | Insert hidden only if product already hides at cap; prefer attempt+error | — | Horizontal scroll |
| Nested host card | — | — | Same as top-level type | Chrome toggles active | Bypass dims card (existing) | — | — |
| Expand maps | All collapsed (except always-on chain strip) | — | Keys for known ids | Toggle flips membership | — | NestingError does not clear | Stale ids for deleted devices ignored on rebuild |
| Meter subscription | `[]` | Brief until post-frame | Ids in viewport | Recompute on expand | — | — | Ids outside viewport dropped |
| NestingError snackbar | Hidden | — | — | — | — | Visible with message | Auto-dismiss |

---

## Responsive / Layout Variants


| Variant | Behavior |
|---------|----------|
| Compact width (phone) | Single horizontal strip scroll; nested expands widen content; chrome toggles stay on card (never move to overflow menu) |
| Normal width | Same structure; more nested regions fit without scroll |
| Wide width | Same; minimap/layout width must include nested expanded widths |
| Must remain visible | Host card chrome toggles for the focused nested host; active virtual strip title |
| May scroll away | Deep nested leaves — user scrolls horizontally |
| Must never wrap | Virtual strip child row stays single-line horizontal |
| Hidden | Collapsed host’s virtual regions |

---

## Demo Script (PO / device ZY32MCWDJ6)

**Prep:** Debug APK installed; project with audio on a track; transport ready.

### A — Chain in chain

1. Device picker → insert **Device Chain** on track.
2. In CHAIN strip → insert another **Device Chain**.
3. In inner CHAIN → insert **Compressor** (or EQ).
4. Play → hear processing; tweak nested compressor → audible.
5. Expand/collapse unrelated hosts → inner chain strip remains usable.

### B — Spectral in chain

1. Inside a chain strip → insert **Spectral Loud Split** (requires WP-06 open types).
2. On nested spectral card → enable **PRE** → insert FX in PRE strip.
3. Expand a **band** → insert **Device Chain** in band → insert Delay in that chain.
4. Enable **POST** → insert FX; confirm PRE/band/POST chrome match top-level spectral.

### C — Deep nest meters

1. Build depth ≥ 2 with a dynamics device that publishes GR (e.g. compressor) at the leaf.
2. Expand every ancestor host so leaf card is on-strip.
3. Scroll leaf into view → **GR meter moves** live.
4. Collapse an ancestor → meter subscription drops leaf when off-layout; re-expand → meter returns.

### D — Capacity error (must not be silent)

1. Fill one branch/strip to soft max (`kMaxDevicesPerNestBranch` = 8).
2. Attempt one more insert → **snackbar** with capacity message; count stays 8.
3. Optional: stack enough time-based/buffer devices to hit `ring_lease_exhausted` → snackbar, no silent mute-only path from UI add.

### E — Regression checks

1. Top-level-only expand/chrome still works (split/MB/spectral/synth/drum).
2. Save/reload deep nest → topology intact; re-expand UI-local.
3. Automate one nested param → curve affects nested device.

---

## UX Issue Checklist


| Check | Result |
|-------|--------|
| Redundant Device-level Modulators/LFOs | Pass — none invented; global mod system only |
| Inconsistent Choice Controls | Pass — no new comboboxes; picker sheet unchanged |
| Inconsistent Filter Selection | Pass — nested devices keep existing panels |
| Octave / Discrete Drag Boxes | Pass — n/a for nesting chrome |
| Visual squeezing & knobs | Pass — nesting adds strips, not knob grids |
| Device width & free space | Risk: deep expand widens strip a lot → horizontal scroll (existing pattern); accept |
| Invented concepts | Pass — recursive reuse of virtual strips only |
| Inconsistent terminology | Pass — PRE/POST/CHAIN/band labels unchanged |
| Missing empty/loading/error | Pass — empty strip + NestingError snackbar specified |
| Bad scroll / compact | Risk: deep nest hard to find — mitigate with always-after-host region order + scroll |
| Silent capacity failure | Explicitly forbidden; demo D verifies |
| Type reject left in UI | Forbidden after WP-06; checklist item for impl |

**Residual risks**

1. File size of `device_chain_row` parts when recursion added — extract shared recursive region builder if >300 LOC growth.
2. Meter math bugs if `DeviceChainLayout` and row emit order diverge — single shared width walk required.
3. Always-on nested `device_chain` strips may feel wide — keep parity with top-level; do not invent collapse unless product asks.

---

## Binding Implementation Rules

Implementation agents **must**:

- Reuse virtual-strip / chrome / snackbar / picker patterns above
- Recurse virtual chrome for every container host at any depth
- Pass nested host ids into existing `addDeviceTo*` methods
- Feed recursive expand state into `MeterSubscription` / layout width
- Surface every `NestingError` bridge code via snackbar (never silent)
- Delete `_*NestingRejectedTypes` in WP-06 (not replace with new lists)

Implementation agents **must not**:

- Invent nest-only toolbars, badges, modals, or terminology
- Persist expansion in project JSON for v1
- Treat nested hosts as card-only (no chrome)
- Swallow `PlatformException` from nest adds
- Replace layout with a vertical nest tree / graph editor

If a layout decision is missing (e.g. expand affordance for a host type that has none today), **stop and report** — do not invent a new control; extend the existing chrome pattern for that type only.

## Implementation Notes

- **WP ownership**: WP-05 (recursive strips/chrome/layout), WP-03 (meters), WP-06 (reject deletion + error surfacing on Flutter add paths), WP-01 (error shape).
- **API**: `PlatformException(code: snake_case NestingErrorCode, message, details)` per `03-api-contracts.md`.
- **Expansion source of truth**: UI-local maps on `DeviceChainRow` state (or equivalent), keyed by device id; pass into meter helper as `expandedDeviceIds` / structured expand sets as needed — one source, no duplicate.
- **Canonical names**: `NestingError`, `VirtualStripHostSnapshot`, `MeterSubscription`, `DeviceChainLayout` — see `02-canonical-vocabulary.md`.
