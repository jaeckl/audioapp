# Library UI Refinements — Integration Plan

## 1. Recommended implementation order

```
Phase 1 (Parallel, 3 workers):
  ┌─────────────────────┐
  │ WP-CACHE            │  Worker A: Flutter cache (isolated)
  ├─────────────────────┤
  │ WP-MIDI (engine)    │  Worker B: C++ polyphonic oscillator + bridge stubs
  ├─────────────────────┤
  │ WP-PRESET (widget)  │  Worker C: PresetPreviewBar widget (no engine yet)
  └─────────────────────┘

Phase 2 (Sequential, 2 workers):
  ┌─────────────────────┐
  │ WP-BRIDGE           │  Worker D: Wire all 4 bridge methods JNI → engine
  └─────────────────────┘
                         (WP-MIDI engine + WP-PRESET engine intermediates ready)

Phase 3 (Sequential, 1 worker):
  ┌─────────────────────┐
  │ WP-CLICK            │  Worker E: Tap→preview dispatch + DAWShell handlers
  └─────────────────────┘
                         (Bridge methods exist, can test with real engine)

Phase 4 (Integration merge):
  ┌─────────────────────┐
  │ Integration merge   │  Merge WP-CLICK + WP-PRESET in library_fly_in_panel.dart
  └─────────────────────┘
```

## 2. Packages that can run in parallel

| Package pair | Reason |
|---|---|
| WP-CACHE + WP-MIDI engine | No file overlap (Flutter vs C++) |
| WP-CACHE + WP-PRESET widget | No file overlap (cache vs UI widget) |
| WP-MIDI engine + WP-PRESET widget | No file overlap (C++ engine vs Flutter widget) |
| WP-CACHE + WP-CLICK | Can merge in `library_content_pane.dart` — low conflict risk |

## 3. Packages that must be sequential

| Prerequisite | Dependent | Reason |
|---|---|---|
| WP-MIDI engine | WP-BRIDGE | Bridge method channel needs engine declarations |
| WP-PRESET engine | WP-BRIDGE | Bridge method channel needs engine declarations |
| WP-BRIDGE | WP-CLICK | DAWShell handlers call bridge methods |
| WP-CLICK | Integration merge | Preview state needed for PresetPreviewBar lifecycle |

## 4. Shared files requiring care

### `library_fly_in_panel.dart` — highest coordination risk
3 packages modify this file: WP-CLICK, WP-PRESET, WP-CACHE.

| Change | Package | Conflict area |
|---|---|---|
| Add `_previewingItemId`, `_previewState` state | WP-CLICK | State fields |
| Place `PresetPreviewBar` in build tree | WP-PRESET | Build method layout |
| Add cache `clear()` on close | WP-CACHE | `close()` / `dispose()` |

**Resolution:** Merge WP-CLICK state first (adds preview tracking), then WP-PRESET widget placement (uses preview state), then WP-CACHE lifecycle (adds clear call in `dispose`).

### `library_content_pane.dart`
2 packages: WP-CLICK, WP-CACHE.

| Change | Package | Conflict area |
|---|---|---|
| Modify `_onItemTap` dispatch | WP-CLICK | Tap handler |
| Wrap `fetchClipPreview` in cache | WP-CACHE | `_LeadingVisual` FutureBuilder |

**Resolution:** WP-CACHE modifies `_LeadingVisual` (cache wrapper), WP-CLICK modifies `_onItemTap` (tap handler) — no overlap.

### `daw_shell.dart`
3 packages: WP-CLICK, WP-MIDI, WP-PRESET.

- WP-CLICK adds `onMidiPreviewTap`/`onAutomationPreviewTap` handlers, wires them to `LibraryFlyInPanel`
- WP-MIDI adds `_previewMidi` handler that calls `bridge.previewMidi()`
- WP-PRESET adds `_previewPreset` handler that calls `bridge.previewPreset()`

**Resolution:** These are separate methods added to the same class. Merge sequentially — WP-CLICK adds callback declarations, WP-MIDI implements MIDI handler, WP-PRESET implements preset handler.

### `engine_bridge.dart` / `EngineHost.hpp` / `EngineHost_commands.cpp`
2 packages: WP-MIDI, WP-PRESET.

Both add method declarations and command handlers. Complex merge.

**Resolution:** Combine both sets of changes in WP-BRIDGE package. WP-MIDI and WP-PRESET produce the engine-side implementations independently, WP-BRIDGE merges them into the shared files.

## 5. Contract gaps or risks

### Gap 1: Preset parameter application in engine
The existing `applySubtractiveSynthPreset` bridge method applies preset params to an existing device. For `previewPreset`, we need a generic mechanism that works for all device types (not just subtractive synth). The contract defines a `PresetPreviewSlot` with a `DeviceSlot` clone, but the mechanism for applying arbitrary preset parameters to arbitrary device types is underspecified.

**Risk:** Medium. May require per-device-type preset application logic in the engine, which could expand scope.

**Mitigation:** Start with subtractive-synth-only preset preview (matching existing `applySubtractiveSynthPreset` pattern). Extend to other device types later.

### Gap 2: MIDI preview through selected track's device chain
The contract specifies playing MIDI notes through the selected track's device chain, but the existing `LivePerformanceMixer` handles live note events through its own voice management. The MIDI preview needs to:
- Schedule note on/off events from clip data at correct beat positions
- Route through the track's device chain (or fallback oscillator)
- Loop continuously

**Risk:** Medium. Scheduling beat-accurate note events from clip data may require new infrastructure or reuse of existing `MidiClipPlayback`.

**Mitigation:** Use the existing `MidiClipPlayback::activeMidiPitchAtBeat` or similar for real-time note lookup, and feed note-on/off events into `LivePerformanceMixer`. Fallback oscillator renders directly when no instrument is available.

### Gap 3: Automation preview engine changes unspecified
Item 1 says automation items should "play back the automation curve on current track." The existing engine has automation clip playback in `processDeviceChain` via `AutomationClipPlayback`. Previewing an automation clip from the library requires:
- Activating the clip's automation points as live modulation
- Without inserting a clip into the arrangement

**Risk:** Low if we reuse existing automation infrastructure. The bridge method `previewAutomation` could temporarily register the clip's automation points as active modulation edges.

**Mitigation:** The automation callback can initially be a no-op or snackbar. The actual playback can be deferred if engine changes are complex. The UI dispatch (WP-CLICK) is separate from engine playback.

### Gap 4: PresetPreviewBar scrub doesn't sync with arrangement playback
Scrubbing in the `PresetPreviewBar` updates a playhead position, but the arrangement playback continues independently. This means scrub position and actual audio are out of sync.

**Risk:** Low. The scrub handle shows an "audition position" — the actual playhead is driven by the engine. This is acceptable for a preview tool. Future refinement can add playhead sync if needed.

### Gap 5: Cache TTL is "session lifetime"
The contract says cache has no expiry, cleared on library close. If `fetchClipPreview` data changes between opens (e.g., MIDI clip content edited), the cache shows stale data. This is acceptable for the stated "no expiry" contract.

**Risk:** Low. Cache is small (50 entries) and only holds waveform peaks, which rarely change for factory clips.

## 6. Rollback strategy

Each package is independently revertible:
- **WP-CACHE:** Remove `library_preview_cache.dart`, revert cache wrapping in `_LeadingVisual`
- **WP-CLICK:** Revert `_onItemTap` dispatch, restore no-op guard, remove new callbacks
- **WP-MIDI:** Remove `FallbackPreviewOscillator`, revert bridge methods
- **WP-PRESET:** Remove `PresetPreviewBar`, revert panel layout, revert bridge methods
- **WP-BRIDGE:** Revert all four bridge methods

## 7. Verification checklist

After all packages merged:

- [ ] Audio clip tap → preview plays (bridge.previewSample)
- [ ] MIDI clip tap → polyphonic preview plays on selected track
- [ ] MIDI clip tap → fallback oscillator when no instrument
- [ ] MIDI preview loops continuously
- [ ] Automation clip tap → preview plays automation curve
- [ ] Preset tap → PresetPreviewBar shown
- [ ] Preset preview bar shows clips for selected track
- [ ] Preset preview bar scrub updates position
- [ ] Preset preview bar loop toggle works
- [ ] Same-item re-tap restarts preview
- [ ] Different-item tap switches preview
- [ ] Library close stops all previews
- [ ] Cache shows shimmer on first load
- [ ] Cache shows data immediately on subsequent loads
- [ ] Cache evicts oldest at 50 entries
- [ ] No regressions in existing library functionality (insert, filter, category switch)