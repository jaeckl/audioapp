# Automation Clips — UX Research & Workflow Options

Research document for **audioapp** automation on mobile. Covers how other DAWs assign automation to parameters, how that maps to our current architecture (untyped tracks, device strip, LFO modulation), and recommended user flows for phone/tablet screens.

**Status:** Draft for product/engineering discussion  
**Related:** `AGENT.md` §8, M08 (`US-08-18`–`US-08-20`), `docs/guidelines/mobile_ux_competitive_analysis.md`

---

## 1. Problem statement

Today every arrangement track is **untyped**: it holds a device chain plus separate MIDI and sample clip lists. Any MIDI clip can live on any track; there is no visual or structural link between a timeline region and a **specific device parameter**.

Automation is different from MIDI/audio:

| Clip kind | Payload | Typical target |
|-----------|---------|----------------|
| MIDI | Notes | Device chain on **same track** (implicit) |
| Sample | `sampleId` | Sampler on **same track** (implicit) |
| **Automation** | Breakpoints / curve | **Explicit** `(deviceId, parameterId)` — may be on another track |

Users need to answer three questions instantly:

1. **What** is being automated? (filter cutoff on `dev-3`, not “some lane”)
2. **Where** does it apply in time? (clip span on timeline)
3. **How** do I edit the shape? (curve editor)

On desktop, “special automation tracks” or stacked lanes make (1) obvious. On a narrow phone screen, that affordance is expensive — we need deliberate mobile patterns.

---

## 2. Current audioapp baseline

### 2.1 Data model (engine)

- **Tracks:** `devices[]`, `midiClips[]`, `sampleClips[]` — no automation clips yet.
- **Clip kind enum:** `ClipContentKind::Automation` exists in C++/Dart but is **not persisted or rendered**.
- **Time-varying control today:** project-global **LFOs** + **modulation edges** (`lfoId → deviceId, paramId, amount`), evaluated at playback — not timeline clips.
- **Documented IDs:** `automation_target_id`, `(device_id, parameter_id)` in architecture docs; not implemented in JSON yet.
- **Backlog:** M08 `US-08-18` (lane data), `US-08-19` (playback), `US-08-20` (filter sweep demo).

### 2.2 UI today

| Surface | Behavior |
|---------|----------|
| **Arrangement** | MIDI + sample clips only |
| **Device strip** | Knobs; MOD panel with LFO grid + connect mode (long-press LFO → long-press knob → amount) |
| **Library → Automation** | Placeholder items (“Volume lane”, “Filter cutoff”) — not wired |
| **Competitive note** | “Automate this” from knob tweak in transport overflow — proposed, not built |

### 2.3 Architectural constraints (non-negotiable)

From `AGENT.md`:

- Automation is **project data** in C++ / `project.json`, not Flutter widget state.
- **Fixed BPM** — breakpoints in beats only (no tempo map).
- **RT-safe playback** — precomputed snapshots on control thread; no JSON/alloc on audio thread.
- Must compose with existing **LFO modulation** (order TBD: base → automation clip → LFO offset).

---

## 3. How other DAWs assign automation to parameters

### 3.1 FL Studio (desktop) — **Automation Clip as reusable generator**

**Mental model:** An automation clip is a **first-class object** in the browser (like a pattern), linked to one or more **targets**. You place clip **instances** on the playlist; the clip holds the envelope curve.

**Assignment flows:**

| Flow | Steps |
|------|--------|
| **Create from parameter** | Right-click knob → “Create automation clip” → clip appears in browser → drag to playlist |
| **Multi-target linking** | Automation clip settings → “Target links” → add/remove controls |
| **Reuse** | Same clip shape on multiple timeline regions / parameters |
| **Edit curve** | Double-click clip → Automation Clip Editor (points, tension, LFO multiply mode, tools) |

**Pros:** Reusable shapes; clear clip boundaries on timeline; FL-native for loop producers.  
**Cons:** Target link is **not always visible** on the playlist row alone — you open clip settings to see links. Many users rely on color/naming discipline.

### 3.2 FL Studio Mobile — **CTRL + dedicated automation track** (closest to us)

**Mental model:** Playlist has **note, audio, and automation tracks**. An automation **track** is a row whose clips drive a linked control.

**Assignment flows:**

| Flow | Steps |
|------|--------|
| **Add automation track** | Tweak target control → Transport **CTRL** → “Add automation track” → add empty clip → Edit |
| **Link to existing track** | Select automation track in playlist → tweak control → CTRL → “Link to current track” |
| **Record while playing** | Move control during record → auto-creates automation track + clip |
| **Edit** | Double-tap clip → point editor (tap add, drag move, long-press delete); **no Bezier tension** on mobile |

**Pros:** Matches FL desktop metaphor; **record-tweak** is fast on touch; CTRL menu is one-handed.  
**Cons:** Extra track type to manage; curve editing is simplified vs desktop.

### 3.3 Ableton Live — **Lane under track (arrangement automation)**

**Mental model:** Press **A** → yellow **automation lanes** under each track. Each lane = one parameter at a time (dropdown to switch).

**Assignment flows:**

| Flow | Steps |
|------|--------|
| **Show lane** | Right-click parameter → “Show Automation in Arrangement” |
| **Multiple params** | Stack multiple lanes vertically on same track |
| **Draw** | Draw mode (B) or record overdub with automation arm |

**Pros:** **Visible binding** — lane header shows parameter name; lives under the track that owns the sound.  
**Cons:** Lanes consume vertical space; on phone, stacked lanes are tight.

### 3.4 Logic Pro — **Track lanes + region vs track automation**

**Mental model:** Automation **lanes** on each track; dropdown picks parameter. **Track automation** (timeline-fixed) vs **region automation** (moves with MIDI/audio clip).

**Assignment:** Press A → choose parameter from lane header → draw breakpoints.

**Pros:** Region automation aligns sweeps with clip boundaries (good for loops).  
**Cons:** Two automation modes confuse beginners; many lanes = vertical scroll hell on phone.

### 3.5 Bitwig — **Joker lane + pinned lanes + modulation**

**Mental model:** Each track has an **automation lane section**. Top “joker” lane follows last touched parameter; **Add Lane** pins a fixed parameter. Separate **modulators** (like our LFOs) for periodic modulation.

**Assignment:** Touch parameter → joker lane shows it; pin to keep visible; modulators via device slot UI.

**Pros:** Fast “automate what I just touched”; clear split between **timeline automation** and **modulation**.  
**Cons:** Dense UI — works better on tablet/desktop.

---

## 4. Comparison matrix (desktop vs mobile fit)

| Approach | Visibility of target | Vertical space | Touch-friendly create | Reusable clip | Mobile fit |
|----------|---------------------|----------------|----------------------|---------------|------------|
| **FL automation clip (browser)** | Medium (name + editor) | Low per row | Medium | **Excellent** | Good on tablet |
| **FL Mobile automation track** | **High** (track = target) | **High** (extra rows) | **Excellent** (CTRL) | Good | **Best documented mobile pattern** |
| **Ableton/Logic lanes under track** | **High** (lane header) | High when stacked | Good | Lane-based, not clip object | OK collapsed |
| **Bitwig joker + pin** | High when pinned | Medium | **Excellent** | Lanes, not clips | Good for “last touched” |
| **Drag clip → LFO grid** | Medium | Low | Experimental | Good | Needs clear drop affordance |
| **Parameter panel mini-lane** | **High** | **Lowest** | Good | Per-parameter | **Best for phone height budget** |

---

## 5. Workflow options for audioapp

Each option includes: user flow, data shape, pros/cons, and mobile notes.

### Option A — **Dedicated automation track (FL Mobile style)**

**Flow:**

1. User tweaks **Filter cutoff** on subtractive synth in device strip.
2. Transport overflow or track header → **“Automate this”**.
3. Engine creates (or selects) an **automation track** linked to `(deviceId, paramId)`.
4. User adds an **automation clip** on that track (library template or empty).
5. Double-tap clip → **fullscreen curve editor** (points + segment curves).

**Visual:** Automation tracks use distinct color (already `LibraryTheme.accentAutomation` purple) and show `deviceName · paramName` in track header.

| Pros | Cons |
|------|------|
| Target always visible in track name | +1 row per automated parameter |
| Matches FL Mobile + user expectation | Many sweeps → tall arrangement |
| Clips are movable/copyable regions | Untyped “music” tracks still mixed with automation tracks unless filtered |
| Clean engine model: `AutomationClip { targetId, points[] }` on automation track | Need track `kind` or `role` enum |

**Mobile:** Use **collapsed automation tracks** (single line height, expand on select). Filter arrangement list: “All / Audio / Automation”.

---

### Option B — **Automation lane under existing track (Ableton/Logic style)**

**Flow:**

1. Select instrument track.
2. Tap **Automation** chevron below track lane → expands sub-lane.
3. Parameter picker → **Filter cutoff** (`dev-2`).
4. Draw breakpoints in expanded lane (or open fullscreen editor for precision).

| Pros | Cons |
|------|------|
| No extra track row — target tied to **sound source** | Sub-lane competes with clip height on phone |
| Familiar to Ableton/Logic users | Multiple params = multiple stacked sub-lanes |
| Implicit routing: “this track’s device chain” | Cross-track targets (master gain) need exception rules |

**Mobile:** Default **one sub-lane**; “+ lane” adds another. Sub-lane height **≥44dp** for touch. Prefer **fullscreen editor** for Bezier work; mini-lane for overview only.

---

### Option C — **Automation clips on untyped tracks (current model, typed clip only)**

**Flow:**

1. Any track can hold MIDI, sample, **and** automation clips (third vector).
2. Each automation clip stores **`automationTargetId`** or `(deviceId, paramId)`.
3. Clip label on timeline: `Filter` with purple styling + device badge.

| Pros | Cons |
|------|------|
| Minimal schema change (add `automationClips[]`) | **Target not visible** until clip is selected |
| Flexible — automation beside MIDI on same row | Users may put automation on “wrong” track |
| Matches `ClipContentKind::Automation` stub | Harder to scan “what’s automated” in dense projects |

**Mobile:** Require **clip subtitle** (`Synth 1 · Cutoff`). Inspector strip on select. Not recommended as **sole** pattern — combine with B or A for discoverability.

---

### Option D — **“Automate this” → device strip mini-lane (parameter-centric)**

**Flow:**

1. Long-press knob → **Automate**.
2. Device strip expands **automation strip** under that knob (horizontal breakpoint view for loop length).
3. Optional: “Promote to arrangement clip” exports to timeline.

| Pros | Cons |
|------|------|
| **Zero timeline vertical cost** | Decoupled from arrangement unless promoted |
| Strong link knob ↔ curve | Doesn’t show multiple params at song level |
| Great for loop-length sweeps while producing | Less useful for long-form arrangement |

**Mobile:** **Strong phone fit** — uses existing bottom strip. Best as **MVP entry** paired with Option A or B for timeline visibility.

---

### Option E — **Drag automation clip onto LFO / modulation grid**

**Flow:**

1. User creates automation clip in library (“Filter sweep template”).
2. Drags clip onto **LFO slot** or modulation grid cell in MOD panel.
3. Drop **assigns target** via connect mode (same as LFO long-press → knob).

| Pros | Cons |
|------|------|
| Reuses familiar MOD connect UX | **Confuses two concepts** — LFO = periodic, automation = timeline envelope |
| No new track type | Drag across strip ↔ arrangement is awkward on phone |
| | Mod grid is per-device; automation clip might target any device |

**Mobile:** Better as **“Assign target”** step in wizard than literal drag-to-LFO. Consider: drop on **knob** (already have connect mode), not LFO grid.

**Verdict:** Use connect-mode **target picking**, not LFO grid, for assignment. LFO grid should stay periodic modulators.

---

### Option F — **Hybrid recommended (phased)**

Align with FL Mobile + Bitwig + our device strip:

| Phase | UX | Engine |
|-------|-----|--------|
| **M8 MVP** | **Option D** + promote to timeline: knob → “Automate this” → mini-lane in strip → one automation clip on **linked automation lane/track** | `AutomationClip`, `AutomationTarget`, linear breakpoints, playback |
| **M8+** | **Option B** collapsed sub-lane under instrument track OR **Option A** dedicated row (user pref) | Bezier segments, clip duplicate |
| **Later** | Reusable clip library (FL desktop style) | Clip templates in library catalog |

---

## 6. Assigning clips to device strips / parameters — concrete flows

### Flow 1 — **Knob-first (recommended primary)**

```
Tweak knob → Strip overflow / long-press → "Automate this"
  → Engine: resolve (selectedDeviceId, paramId)
  → Create AutomationTarget + empty AutomationClip at playhead (1 bar)
  → Open curve editor (fullscreen)
```

**Why:** Matches FL Mobile CTRL, our competitive analysis, and MOD connect mode. One hand on strip, no drag precision required.

### Flow 2 — **Timeline-first**

```
Library → Automation → "Filter cutoff" template
  → Tap track row → clip placed at playhead
  → If track has one filter-capable device: auto-bind
  → Else: "Choose parameter" sheet listing track devices + params
```

**Why:** Supports power users and template library placeholders already in `library_catalog.dart`.

### Flow 3 — **Record automation (touch write)**

```
Transport record + automation arm ON
  → User drags knob during playback
  → Engine writes breakpoints at playhead intervals (throttled)
  → Clip grows on automation lane
```

**Why:** Fastest performance capture; FL Mobile default. Needs **automation arm** distinct from MIDI record.

### Flow 4 — **Promote from LFO (explicitly NOT merge)**

```
LFO modulating cutoff (existing)
  → Menu: "Copy to automation clip" (optional future)
  → Bakes one LFO cycle or current snapshot into timeline clip
```

**Why:** Keeps LFO and automation separate; optional conversion only.

### Flow 5 — **Drag-to-target (tablet only)**

```
Drag clip from library
  → Drop on device knob OR track header
  → Drop target highlights; haptic on valid param
```

**Why:** Nice on tablet; **secondary** on phone (fat finger, scroll conflicts).

---

## 7. Curve editor UX (Bezier / tools)

Desktop FL offers tension handles, smooth tools, LFO multiply mode. Mobile FL **intentionally simplifies** to points + straight segments.

### Mobile-realistic editor (fullscreen)

```
┌─────────────────────────────────────┐
│ ← Filter cutoff · Synth 1    Done   │
├─────────────────────────────────────┤
│  [Value axis]                        │
│     ●──────╮                         │
│            ╰──●                      │
│  [Time / beats aligned to clip]      │
├─────────────────────────────────────┤
│  + point   ⌫   Snap   Linear / Curve  │
└─────────────────────────────────────┘
```

| Tool | MVP | Later |
|------|-----|-------|
| Add point (tap) | ✓ | |
| Drag point | ✓ | |
| Delete (long-press) | ✓ | |
| Segment shape | Linear | Bezier tension (FL “tension”) |
| Multi-select | | Tablet lasso |
| Snap to grid | ✓ (1/4 bar) | Configurable |
| Value readout | ✓ | |
| Copy/paste envelope | | ✓ |

**Phone rule:** Editing happens **fullscreen**, not inline in 32dp lane. Inline lane = preview + tap-to-open-editor.

**Bezier on touch:** Use **segment mode toggle** (linear / smooth / stepped) per segment rather than micro tension handles — handles are hard sub-44dp.

---

## 8. Track typing strategy

Three viable models:

| Model | Description | Recommendation |
|-------|-------------|----------------|
| **Untyped track, typed clip** | Current; add `automationClips[]` | OK internally, weak UX alone |
| **Track role enum** | `Instrument \| Automation \| Master` | **Recommended** for arrangement filtering |
| **Separate automation track list** | Parallel array in project | Heavy; avoid |

**Suggested `TrackRole`:**

- `instrument` (default) — MIDI/sample clips, device chain
- `automation` — automation clips only, no audio/MIDI; header shows bound target
- (future) `audio`, `bus`

Instrument tracks may still host **automation sub-lanes** (Option B) without changing role.

---

## 9. Data model sketch (engine-neutral)

```text
AutomationTarget
  id: automation_target_id (stable)
  deviceId: string
  parameterId: string
  displayName: string (cached for UI)

AutomationClip (on track)
  id, startBeat, lengthBeats
  targetId: automation_target_id
  points: [{ beat, value }]           // beat relative to clip start
  segments: [{ index, curve: linear|smooth|step }]  // later

Playback composition (proposal):
  baseValue = device stored param
  automationValue = evaluateClip(target, playhead)
  lfoOffset = existing modEdges
  final = clamp( compose(base, automation, lfo), paramMin, paramMax )
```

**Relationship to LFO edges:**

| Mechanism | Timebase | Use case |
|-----------|----------|----------|
| LFO + edge | Continuous / periodic | Vibrato, filter wobble |
| Automation clip | Timeline regions | Builds, drops, one-shot sweeps |

Fix mod edge key to `(lfoId, deviceId, paramId)` before automation ships — avoids collision with automation targets.

---

## 10. Mobile screen recommendations

Based on `mobile_ux_competitive_analysis.md` vertical budget (~640dp usable):

| Priority | Pattern | Rationale |
|----------|---------|-----------|
| **P0** | Knob → “Automate this” | Lowest friction; no new timeline rows initially |
| **P0** | Fullscreen curve editor | Bezier/precision need space |
| **P0** | Purple automation clip styling + `Device · Param` label | Visibility without desktop lanes |
| **P1** | One collapsible automation sub-lane under instrument track | Balance visibility vs height |
| **P1** | Automation arm + record tweaks | FL Mobile parity |
| **P2** | Dedicated automation track rows | When project has many sweeps |
| **P2** | Drag-from-library assignment | Tablet |
| **Avoid** | Many stacked lanes on phone portrait | Scroll fatigue |
| **Avoid** | Drag clip onto LFO grid | Conceptual mismatch |

**Arrangement + device strip rule (unchanged):** Do not show full strip + fullscreen automation editor + keyboard simultaneously on phone — editor is modal.

---

## 11. Open product decisions

1. **Track vs lane default:** Instrument sub-lane (Ableton) vs automation track row (FL Mobile) as default — could be Settings toggle.
2. **Same-track MIDI + automation clips:** Allowed on instrument track, or force automation-only rows?
3. **Master / send automation:** Separate master automation track or master “device” in strip?
4. **Clip vs lane persistence:** Breakpoints in movable clips only, or also orphan lane data (Logic region vs track)?
5. **LFO interaction:** Additive vs multiplicative vs override when both target same param.
6. **MVP curve:** Linear segments only vs one “smooth” preset per segment.

---

## 12. Suggested MVP slice (maps to M08 tickets)

**Demo script (PO):**

1. Add track + subtractive synth.
2. Long-press **Filter cutoff** → **Automate this**.
3. Fullscreen editor opens; tap two points; middle value lower → sweep shape.
4. Clip appears on timeline (purple, labeled `Synth · Filter cutoff`).
5. Play → audible filter sweep; save/load restores curve.

**Engine:** `US-08-18` target + clip + breakpoints JSON.  
**Playback:** `US-08-19` evaluate at playhead.  
**UI:** `US-08-04` companions + this doc’s Flow 1 + fullscreen editor.

---

## 13. References

- [FL Studio — Automation Clips](https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/playlist_automationclip.htm)
- [FL Studio Mobile — Automation Clip editor](https://www.image-line.com/fl-studio-learning/fl-studio-mobile-online-manual/html/plugins/FL%20Studio%20Mobile_Editors.htm)
- [FL Studio Mobile — Playlist / CTRL automation track](https://www.image-line.com/fl-studio-learning/fl-studio-mobile-online-manual/html/plugins/FL%20Studio%20Mobile_Playlist.htm)
- [Bitwig — Automation lanes](https://www.bitwig.com/userguide/latest/automation)
- Internal: `AGENT.md` §8, `docs/architecture/project_model.md`, `docs/guidelines/mobile_ux_competitive_analysis.md`
- Code: `TimelineClipTypes.hpp`, `ModulationGraph`, `modulation_grid.dart`, `library_catalog.dart`
