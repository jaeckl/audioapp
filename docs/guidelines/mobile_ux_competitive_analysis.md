# Mobile UX — Competitive analysis (Ableton Note vs FL Studio Mobile)

Research synthesis for **audioapp** layout and interaction design.  
Sources: Ableton Note manual (2025), Image-Line FL Studio Mobile manual, CDM hands-on, Figma Config 2024 (Note lead designer Pablo Sánchez).

---

## 1. Product positioning (where we sit)

| | **Ableton Note** | **FL Studio Mobile** | **audioapp (target)** |
|---|------------------|----------------------|------------------------|
| Metaphor | Musical notepad / Voice Memos | Pocket FL Studio | Semi-pro mobile DAW |
| Primary surface | Session grid (clip launcher) | Playlist (linear timeline) | **Arrangement timeline** |
| Depth model | 2 screens: Session ↔ Instrument | 5+ workspaces (swap, don’t stack) | **2–3 modes**: Arrange / Play / Mix |
| Desktop handoff | Cloud → Live Sets | Native .flm → FL Studio | `.audioapp.zip` diffable project |
| Density | Very low chrome, icon-only | Medium; color + icons | **Low chrome, high function** |

We are **not** building Note (sketchpad). We **are** building closer to FL Mobile (arrangement DAW) but should steal Note’s **spatial discipline** and **touch-first vocabulary**.

---

## 2. Layout anatomy

### Ableton Note — Session View (phone)

```
┌──────────────────────────────────────┐
│ ←  Set name                    ···   │  ← wayfinding only (tempo in ···)
├──────────────────────────────────────┤
│  Drums │ Bass │ Keys │  +           │  ← vertical track columns
│  ┌──┐  ┌──┐  ┌──┐                   │
│  │■ │  │  │  │■ │   scene rows      │  ← equal square clip slots
│  └──┘  └──┘  └──┘                   │
│  ┌──┐  ┌──┐  ┌──┐                   │
│  │  │  │■ │  │  │                   │
│  └──┘  └──┘  └──┘                   │
├──────────────────────────────────────┤
│  ↶ ↷  │ MIX │ 1 │        ▶         │  ← fixed bottom dock, icons only
└──────────────────────────────────────┘
```

**Instrument View** (full takeover): pads/keys ~70% height, tiny clip preview strip, preset + 2 FX slots, back arrow returns to grid.

**Lessons**

- One primary canvas; everything else is **modal full-screen**.
- Bottom dock = **4 actions max** (undo, mixer overlay, scene #, transport).
- **No text labels** on chrome — icons + muscle memory (Note: “touch instead of read”).
- Mixer is **overlay**, not a separate tab.
- Clip slots are **large touch targets** with generous gutters.

### FL Studio Mobile — phone

```
┌──────────────────────────────────────┐
│  PLAYLIST workspace (when active)      │
│  [track icon] ═══ note clip ═══      │
│  [track icon] ═══ audio ═══          │  ← horizontal time, vertical tracks
│         [rack ▸] on selected track   │  ← rack slides from right
├──────────────────────────────────────┤
│  (switch workspace: Rack / Mixer /     │
│   Piano / Drums / Home)              │  ← NOT split view on phone
└──────────────────────────────────────┘
```

**Lessons**

- **Single-view discipline**: playlist OR rack OR keyboard — never all three on a phone.
- **Gesture ladder**: short tap = light action, long tap = menu, double tap = deep editor.
- Track icon is the **hub** for channel settings, rack, mixer strip.
- Admin (save, shop, MIDI) lives in **Home**, away from creative surfaces.
- Color distinguishes clip types; waveform visible in playlist.

### audioapp — current shell

```
┌──────────────────────────────────────┐
│  BPM · playhead · loop · version     │  transport
├──────────────────────────────────────┤
│  Arrangement OR Mixer OR Library OR  │  tab swaps entire body
│  Settings                            │
├──────────────────────────────────────┤
│  Device strip (when on Arrangement)  │  fixed ~236dp design height
├──────────────────────────────────────┤
│  Arr │ Mix │ Lib │ Set                │  64dp nav (+ landscape rail)
└──────────────────────────────────────┘
```

**Gap vs references**

- We stack **transport + tab body + device strip + nav** → 4 bands on phone; Note uses 2 (grid + dock).
- Library and Settings as peers of Arrangement **competes** with timeline + strip for vertical space.
- Device strip always visible is **Bitwig-correct** but phone-tight without collapse.

---

## 3. Interaction patterns worth adopting

### From Ableton Note

| Pattern | Implementation idea for audioapp |
|---------|--------------------------------|
| **Capture without Play** | “Record arm” on track: tap pads/keys, then commit clip length from performance |
| **Icon bottom dock** | Replace text nav labels with icons + tooltips; keep text inside editors only |
| **Clip slot mental model** | Empty slots show `+`; filled slots show color + 1-word label max |
| **Swipe on bar ruler** | Swipe timeline bar numbers to duplicate section (later) |
| **Mixer overlay** | Mixer as bottom sheet over arrangement, not full tab swap |
| **Set settings in ···** | BPM/key/metronome/export in overflow, not permanent transport clutter |
| **High contrast theme** | Optional second theme for sunlight / accessibility |

### From FL Studio Mobile

| Pattern | Implementation idea for audioapp |
|---------|--------------------------------|
| **Double-tap → editor** | Already: MIDI → piano roll; extend consistently to audio → wave editor |
| **Long-tap track header → menu** | Already partial; unify: Add clip / Delete / Rack / Color |
| **Rack from track edge** | Device chain as slide-over from track header (strip = collapsed rack) |
| **Workspace switching** | Explicit modes: **Arrange** \| **Play** (keys/pads) \| **Mix** |
| **Home for admin** | Keep Save/Export/Load in Settings but consider “project” sheet from top bar |
| **CTRL automation** | Tweak knob → “Automate this” in transport overflow (matches our backlog) |

### Gesture vocabulary (proposed standard)

| Gesture | Scope | Action |
|---------|-------|--------|
| Short tap | Clip | Select / open light inspector |
| Double tap | Clip | Open editor (piano roll / sampler fullscreen) |
| Long press + drag | Clip | Move (already) |
| Long press | Track header | Context menu |
| Long press | Playhead area | Scrub |
| Pinch | Timeline | Zoom (already) |
| Swipe horizontal | Device strip | Switch devices in chain (future) |

---

## 4. Phone vertical budget (design rule)

On a **6.5″ phone in portrait**, treat usable height as ~640dp after system bars.

| Zone | Note | FL Mobile | **audioapp target** |
|------|------|-----------|---------------------|
| Chrome (transport + nav) | ~56dp | ~48dp | **≤56dp combined** |
| Primary canvas | ~520dp | ~520dp (one workspace) | **≥400dp arrangement** |
| Instrument / strip | 0 in grid view; full screen when playing | Replaces canvas in Play mode | **≤180dp collapsed strip OR fullscreen** |
| Bottom dock / nav | ~48dp icons | workspace switcher | **48–64dp icon nav** |

**Rule:** Never show Arrangement + full device strip + keyboard simultaneously on phone portrait.

---

## 5. Recommended shell for audioapp

### Phase A — Arrangement DAW (now → M09)

**Portrait**

```
┌──────────────────────────────────────┐
│  ▶  120  1.3  ···                    │  compact transport (play, bpm, bar, overflow)
├──────────────────────────────────────┤
│                                      │
│         ARRANGEMENT                  │  maximum height
│                                      │
├──────────────────────────────────────┤
│  [Sampler ▾]  waveform + ADSR peek   │  collapsed strip (~120dp); tap ↑ = fullscreen
├──────────────────────────────────────┤
│   ◫      ◫      ♫      ⚙             │  Arrange / Mix / Sounds / Project
└──────────────────────────────────────┘
```

- **Sounds** tab = library + import (not separate “settings” clutter).
- **Project** = save/load/export (FL Home panel pattern).
- **Mix** = bottom sheet or full screen, not tiny tab with duplicate strip.

**Landscape**

- Keep side nav rail (already).
- Timeline + collapsed strip side-by-side OR strip as right drawer (Bitwig inspector pattern).

### Phase B — Sketch lane (post-MVP, optional)

Borrow Note **without** replacing arrangement:

- Secondary **Session** tab or “Ideas” lane: 4×4 clip matrix per track for loop audition.
- Drag clip from session → arrangement to “commit” idea (Note → Live metaphor).

---

## 6. Device strip guidelines (Bitwig on phone)

| Principle | Detail |
|-----------|--------|
| **Fixed design size** | Keep 520×236 design canvas + uniform scale (done) |
| **One tab per page** | Sample / Env / Filter / Level — never all knobs at once (FLM / Note pattern) |
| **Big knobs** | Strip ~56dp, editor ~76dp (`DeviceKnobSizes`) |
| **Collapse by default** | ~112dp peek on phone; expand for tabbed editing |
| **Fullscreen = edit** | ADSR, filter, trim only in landscape editor (done) |
| **No duplicate controls** | Strip preview only; no full mixer in strip |
| **Color accent** | One accent per device type (sampler orange, etc.) |

---

## 7. Visual language

| Token | Note | FL Mobile | **audioapp** |
|-------|------|-----------|--------------|
| Background | Near black + high contrast option | Dark gray + saturated clips | `#0E0E14` / `#1A1A22` (keep) |
| Accent | Minimal white icons | Strong clip colors | **One warm accent** (`#E8A54B` sampler) |
| Typography | Almost none on chrome | Labels on clips | Labels on clips + headers only |
| Corner radius | Small, grid squares | Rounded clips | 6–8dp clips, 4dp panels |
| Touch target | Full clip cell | Clip height ~44dp+ | **min 44dp** headers, **48dp** clip min height |

---

## 8. What NOT to copy

- Note’s **8×8 session limit** — we need longer arrangements.
- FL’s **workspace confusion** (users cite missing top transport) — keep play/BPM always visible.
- FL **no split screen on phone** — we already use fullscreen editors; don’t add a fourth visible band.
- Note’s **no audio tracks** — we need sample clips on timeline (already).
- Over-tabbed shell (4 equal tabs) — merge admin + library.

---

## 9. Next implementation priorities (UX)

1. **Collapse device strip** to ~120dp summary card; expand to fullscreen/editor.
2. **Icon-only bottom nav** with tooltips; rename Settings → Project.
3. **Transport overflow** (· · ·) for BPM fine-tune, loop length, export, metronome.
4. **Mixer as sheet** from transport or track header, not isolated tab.
5. **Play mode** (future): fullscreen pads/keys; arrangement hidden; one tap back.
6. Document gestures in onboarding tooltip once per install.

---

## 10. References

- [Ableton Note manual](https://www.ableton.com/en/note/manual/)
- [CDM: Note hands-on](https://cdm.link/heres-what-to-know-about-note-abletons-mobile-musical-sketchpad-for-ios/)
- [Figma Config: Note design rules](https://www.figma.com/blog/pablo-sanchezs-7-rules-for-designing-the-unexpected/)
- [FL Studio Mobile manual — Playlist](https://www.image-line.com/fl-studio-learning/fl-studio-mobile-online-manual/html/plugins/FL%20Studio%20Mobile_Playlist.htm)
- [FL Studio Mobile — Rack](https://www.image-line.com/fl-studio-learning/fl-studio-mobile-online-manual/html/plugins/FL%20Studio%20Mobile_Rack.htm)
- Internal: [mobile_ui_guidelines.md](mobile_ui_guidelines.md), [AGENT.md](../../AGENT.md) §1
