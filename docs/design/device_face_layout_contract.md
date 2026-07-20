# Device face layout contract

**Companion to:** [daw_elements.svg](../architecture/daw_elements.svg) (component samples + chassis)  
**Chrome ownership:** [device_strip_chrome.md](device_strip_chrome.md) · [ADR-0008](../adr/ADR-0008-device-strip-ui-chrome.md)  
**Audience:** humans + LLMs designing any `*DevicePanel` face inside the strip.

This document is **prescriptive**. `daw_elements.svg` shows *what components look like*; this contract says *how to compose a face* so devices stay consistent.

**Hard rule — knobs are always flat.** No radial gradients, dome bevels, inner-shadow “caps,” or other pseudo-skeuomorphic knob materials. Bitwig hierarchy lessons apply; Bitwig knob chrome does **not**.

**Hard rule — preview is earned, never gifted.** A response / scope / analyzer / curve panel may exist only when it carries **parameter-mapped or realtime signal truth**. Decorative “looks pro” screens are a contract violation. When a preview *does* earn existence, prefer the **full-bleed hero + floating knob plate** layout (Filter pattern) — not a postage-stamp graph above a separate control well.

---

## 0. Non-negotiable chrome (outside the face)

Every expanded slot:

```text
[Tool rail] [Mod?] [LFO props?] [INPUT?] [ Card: header tabs + FACE BODY ] [OUTPUT?]
```

| Column | Owns |
|--------|------|
| Tool rail | Bypass, library, mod toggle, delete, vertical device name |
| Header tab bar (40px) | Container / routing tabs; identity strip may be **blank** when tool rail already names the device (Filter) |
| Input panel | In-meter, in-trim, sidechain key — **only** when the device has those concerns |
| Output panel | Out gain / pan / mix / width / GR / or **empty cap** — type-specific; never Dynamics GR by accident |
| **Face body** | DSP-specific process UI only |

Face body height ≈ strip `320` − card header `40` − vertical padding. FX face widths typically **200–270** (see metrics).

---

## 1. Face hierarchy contract (C1)

Exactly **one hero** per face (or per tab).

### Preview layout mandate (when preview is legitimate — see §4)

If the face has a **legitimate** transfer / response / scope / analyzer preview, the default composition is **not negotiable**:

1. **Full-bleed hero screen** fills the entire face body (`heroScreen` `#07070A`). No letterbox gutters. No fake “viewport” padding that invents empty chassis bands.
2. **Floating control plate** (`panelElevated`) sits **on top of** that screen at the bottom (inset ~6px). Modes + primary knobs live **in the plate**, not in a second well below a short graph.
3. Graph paint region = body minus plate footprint. Scale labels / live readouts stay inside the paint region (don’t hide under the plate).

```text
REQUIRED when preview is legitimate (Filter reference):
┌─────────────────────────────────────┐
│/////////// HERO SCREEN /////////////│  full-bleed
│  curve / scope / nodes              │
│  ┌───────────────────────────────┐  │
│  │ modes · primary knobs         │  │  floating plate ON screen
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Forbidden substitutes for a legitimate preview:**

| Anti-pattern | Why it fails |
|--------------|--------------|
| Short graph strip + separate knob well below | Two competing surfaces; graph reads as chrome garnish |
| Graph in a nested card with chassis padding | Fake depth; wastes face height; breaks shade ladder |
| `DeviceStripViewport` letterbox around a screen that should full-bleed | Invents empty bands; Filter already rejected this |
| Controls floating in leftover `Expanded` *without* a plate when a full-bleed screen exists | Knobs look orphaned on black |

**Allowed without full-bleed:** faces with **no** legitimate preview (utility, pure toggle/knob FX) — use control wells only. Do **not** invent a black screen to “match Filter.”

### Vertical caste (fixed order)

1. **HERO screen** — darkest surface. Either full-bleed (preview faces) or absent (no-preview faces).
2. **Floating plate / control well** — modes + primary knobs. On preview faces: one elevated plate on the screen. On no-preview faces: a single well on chassis.
3. **Optional footer** — secondary toggles only if not owned by rails.

### Shade ladder (monotonic)

| Surface | Token / fill | Role |
|---------|--------------|------|
| Graph interior | `#07070A` or `panelScreen` | Hero only |
| Control well / floating plate | `panelElevated` `#16161E` | Knobs / segments |
| Card chassis | `#1A1A24` | Face background (visible only when no full-bleed hero) |
| Header | `#22222E` | Tabs — not a face well |

**Forbidden:** two competing heroes; card-inside-card-inside-card (nesting depth > 2: chassis → well → control).  
**Allowed (Filter-like):** one full-bleed hero with a single floating control plate — plate is the control well, not a second hero.

---

## 2. Surfaces, borders, radius (C2) — flat materials

### Materials (flat system)

| Element | Fill | Edge | Notes |
|---------|------|------|-------|
| Hero screen | near-black | optional 1px `white@8–10%` **or** shade step only | Recess by **shade**, not bevel |
| Control well | `panelElevated` | shade step or 1px `white@6%` hairline | No drop shadow stacks |
| Segment / mode cell | transparent or accent wash ≤12% | hairline divider `white@8–10%` | See §5 |
| **Knob** | flat disc `#14141C` (or theme) | **no** stroke required; value arc outside | **Always flat** — no dome, no rim highlight, no radial gradient |

### Border taxonomy

| Kind | Use |
|------|-----|
| Shade step | Structural nesting (screen vs well) |
| Hairline `white@5–10%` | Grouping *within* one shade |
| Chassis stroke `#4A4A5C` 1.5px | Card / rail outer edge only |

### Radius scale

| Token | px | Use |
|-------|-----|-----|
| Screen / well | 4 | Nested face modules (match hard card language) |
| Buttons / chips | 3–4 | Face toggles |
| Chassis | 2 | Outer card (rails attach sharp) |
| Knob | circle | Flat disc — not a soft “pill knob” |

---

## 3. Flat knob recipe (C2 continued)

Follow `daw_elements.svg` knob layers **without** depth materials:

1. Flat circular background  
2. Range arc (neutral, partial)  
3. Value arc (device accent or automation/modulation color)  
4. Pointer / handle mark  
5. Optional display value **below** or transient-on-drag — prefer below for compact knobs  

| Size | Visual Ø | Min hit |
|------|----------|---------|
| Strip primary | 56 (`DeviceKnobSizes.strip`) | ≥48dp invisible |
| Strip compact | 44 | ≥48dp |
| Output / input trim | smaller rail knobs | ≥44dp |

**Do:** accent on value arc + selected graph node only.  
**Don’t:** paint whole knob face with device accent; don’t add skeuo lighting.

States (keep SVG matrix): default / automated / modulated / connect-glow / link.

---

## 4. Preview necessity gate (C3) — earn the screen or don’t ship it

A preview / graph / scope / analyzer / “screen” widget is a **privileged surface**. It burns face height, forces the full-bleed + floating-plate layout (§1), and invites cargo-cult copies. Gate it hard.

### Legitimate preview (PASS — ship full-bleed + plate)

The screen must continuously (or on every relevant param change) show at least one of:

| Class | Definition | Examples that pass |
|-------|------------|--------------------|
| **Transfer / response curve** | Drawn from DSP params; moving a mapped control visibly reshapes the plot | Filter magnitude; EQ band response; waveshaper transfer |
| **Multi-node process map** | Nodes are editable params; colors/readouts bind to those params | 4-band EQ nodes; distortion character nodes |
| **Realtime signal preview** | Driven by live audio / MIDI / analyzer buffers from the engine | Scope, spectrum, loudness history, dynamics gain-reduction over time |
| **Time-domain shape tied to params** | Waveform / LFO shape is the control surface or mirrors rate/depth/shape params | Chorus LFO shape; phaser stages when stages map to visible notches |

If none of the rows apply → **FAIL**. No screen. Use wells + knobs only.

### Illegitimate preview (FAIL — delete before merge)

| Anti-pattern | Critique |
|--------------|----------|
| Static backdrop gradient / fake FFT that ignores params | Decor. Lies to the user. |
| “Analyzer” that never reads engine meters / buffers | Theater. |
| Curve that does not move when primary knobs move | Broken contract — either wire it or remove it. |
| Graph added “because Filter has one” / “looks Bitwig” | Cargo cult. Filter earned its curve. |
| Mini chart to fill empty vertical space | Space is not a product requirement. |
| Marketing silhouette / brand mark as hero | Brand lives in chrome/identity, not the process face. |
| Duplicate of a meter already owned by input/output rails | Chrome theft — use the rail. |

**Reviewer veto line:** *“What parameter or buffer feeds this pixel? Show the binding.”* No binding → no preview.

### Interaction defaults (once preview PASSes)

- Knobs drive the curve/nodes; graph drag-edit only when a ticket explicitly requires it.
- Hit targets on interactive nodes ≥28px.
- Headroom: scale so typical peaks aren’t crushed into dead air (e.g. filter −24…+6, not empty +12).
- Labels / live readouts stay in the paint region above the floating plate.

### Subtype grammar (after PASS)

| Subtype | Examples | Rules |
|---------|----------|-------|
| Transfer curve | Filter | Log freq 20–20k; one 0 dB line labeled; soft grid; curve + optional soft fill; cutoff locator = guide + **dot on curve** |
| Multi-node EQ-ish | Distortion / 4-band | Nodes color-coded; readouts match node colors |
| Waveform / LFO | Chorus | Screen is hero; shape selector is plate chrome |
| Scope / dynamics | Gate | Threshold / GR in-screen or in **output** rail — not both duplicated |

---

## 5. Selection affordance (C4)

| Control type | Selected look |
|--------------|---------------|
| Graph **mode** icons (LP/HP/…) | Accent **underline** (1–2px) under glyph + optional ≤12% wash; icon→accent |
| Named **segment** (model A/B) | Low filled segment in a well |
| Boolean **toggle** (Wet FX, Wide) | Accent **fill wash** |
| Header **tab** | Structural tab surface (header chrome) |

Mode icon row sits in the floating control plate. Not a separate chip cluster outside the plate. Not a second bar under a short graph.

Touch: row height ≥30 visual; prefer ≥42 hit if layout allows.

---

## 6. Chrome ownership table (C5) — face exclusion zone

| Concern | Owner | Face may… |
|---------|-------|-----------|
| Device name | Tool rail | **not** reprint large title |
| Bypass / library / mod / delete | Tool rail | **not** duplicate |
| Container / routing tabs | Header | use tabs; **not** fake a second tab bar in body |
| Input meter / in-trim / SC key | Input panel | show detector UI that isn’t rail-owned |
| Out gain / pan / mix / width / GR | Output panel | **not** duplicate Mix/Width/Wet Gain in body |
| DSP process params | Face | own them |
| Bitwig-style right “Wet/Mix” column | **Map to output panel** | collapse; don’t invent a third right column unless archetype exception documented |

Attached-edge geometry: face corners square where rails attach; outer rounding on far rail edges only.

---

## 7. Density & grid (C6)

| Metric | Value |
|--------|-------|
| Strip body height | 320 |
| Header | 40 |
| Face h-pad (FX) | ~6–12 (full-bleed hero: **0** body letterbox; plate inset ~6) |
| Screen → plate | plate floats on screen; no separate well below |
| Module → knobs gap | 8 |
| Inter-knob gap | 8 (`dynamicsFxKnobGap`) |
| Nesting depth max | 2 (chassis → well → control; full-bleed skips visible chassis) |
| FX width breakpoints | ~200 / 230 / 270 |

**Budget (compact FX ~216):** ≤1 hero (only if §4 PASS), ≤1 mode row, ≤4 primary knobs in the plate/well (more → tabs or widen).

---

## 8. Device archetypes (C7)

Pick an archetype; don’t invent a layout.  
**Ticket must state:** archetype · §4 preview verdict (PASS class / FAIL) · hero · rail owners.

### Filter-like (default for any §4 PASS transfer / response face)

`Full-bleed hero` + **floating control plate** (modes underline + primary knobs).  
Reference impl: `FilterSectionLayout`.  
Freq / scale labels and live readouts stay in the paint region (above the plate).  
No input chrome unless the device truly has sidechain / in-meter needs; empty or Fx output per chrome registry — never Dynamics GR by accident.

### EQ / Distortion-like

§4 PASS (multi-node / transfer) → same **full-bleed + plate** shell as Filter-like.  
Nodes + curve on screen; character knobs / band selects in the plate.  
Wet/mix → **output** rail.  
**Do not** invent a short EQ strip “because EQ screenshots look that way.”

### Time FX / Chorus-like

§4 PASS only if waveform / LFO shape is param-bound or live. Then full-bleed + plate (shape chrome in plate).  
Otherwise: cell grid / rate wells only — **no** fake waveform wallpaper.  
Wet/mix/width → **output** rail.

### Dynamics / Gate-like

§4 PASS if scope / GR history / threshold overlay is fed by real detectors. Full-bleed + plate.  
Routing / SC → **header/input**. GR/level meters → **output** rail (don’t duplicate in-face).  
Threshold-only with no live plot → knobs in a well; skip the black screen.

### Utility-like

Few toggles + knobs. **§4 FAIL by default.** Meter only if rail-owned or a true live buffer — never a decorative graph.

### Instrument-like

Osc / wavetable / sample preview PASSes only when it shows the loaded/generated source or live voice. Full-bleed + plate (or tabbed wells under a real preview).  
Static “synth silhouette” art → FAIL.

### Analysis devices

Realtime buffers only. Full-bleed hero is the product; plate may be empty or minimal controls. Empty output cap is fine.

---

## 9. Mobile vs desktop density (C8)

Bitwig is mouse-dense. We are thumb-dense.

| Keep on phone | Prune / relocate |
|---------------|------------------|
| One hero + primary params | Tiny tertiary knobs |
| Mode row with clear hit | Desktop-only icon forests |
| Output-rail mix/width | In-face duplicate wet column |

**Don’t** scale a Bitwig screenshot down. Prune roles, enlarge hits (≥48dp), gesture-capture: knob/graph drag wins over strip scroll once movement threshold passed.

---

## 10. Right-column contract (C9)

**Default:** Bitwig’s `Wet FX / Width / Wet Gain / Mix` stack → **output panel** registry for that device type.

In-face right column only if:

- No output panel for that type, **and**
- Archetype doc explicitly allows a narrow utility column, **and**
- It does not duplicate rail-owned params.

---

## 11. Typography / readout grammar (C10)

| Role | Style |
|------|-------|
| Live graph readout | 8–9px, `white@50–55%`, top of screen or under graph |
| Knob display value | Prefer operational (`1.24 kHz`, `Q 0.71`) over raw 0–1 |
| Knob label | 8px uppercase quiet (`CUTOFF`, `RES`) |
| Node-linked readout | Color = owning node accent |

Freq abbreviations: `20`, `100`, `1k`, `10k`, `20k`.

---

## 12. Semantic color budget

| Role | Color |
|------|-------|
| Neutral UI | greys / white alphas |
| Device identity | per-type accent (stripe, curve, selected mode, value arc) |
| Automation | system purple (existing) |
| Modulation | system mod arc (existing) |
| Clip / warn | red sparingly |
| Live meter | meter blue/green — not device accent everywhere |

**Precedence when stacked:** connect/link highlight > automation/mod overlays > device accent.

---

## 13. Do / don’t (LLM checklist)

**Do**

- Run §4 gate **before** adding any `CustomPaint` / graph / scope  
- On §4 PASS: full-bleed hero + floating plate (`FilterSectionLayout` pattern)  
- State archetype + chrome owners + preview class (transfer / realtime / FAIL)  
- One hero; modes in the plate; flat knobs  
- Put Mix/Width/Wet in output panel  
- Use underline for modes, wash for toggles  

**Don’t**

- Ship a preview “to look finished” / “match Bitwig” / “fill space”  
- Short graph strip + separate knob well when a legitimate curve exists  
- Skeuomorphic / domed knobs  
- Reprint device name or bypass on the face (tool rail owns name; blank header OK)  
- Nested cards with radius 6 soft marshmallow on a radius-2 chassis  
- Icon-only modes with invisible selection  
- Letterbox / viewport wrappers around a full-bleed hero  
- Dynamics input/GR chrome on devices with no sidechain / GR  

---

## 14. Acceptance (any new / redesigned face)

1. **§4 verdict written:** PASS (class + binding) or FAIL (no screen).  
2. If PASS: full-bleed + floating plate; no letterbox; plate owns modes + primary knobs.  
3. From arm’s length: name the active mode / hero state in &lt;1s.  
4. Confirm Mix/Gain/Pan/GR not duplicated vs rails; input panel only if sidechain/in-meter real.  
5. Knobs read flat; accent only on arcs/selection.  
6. Horizontal strip scroll still works; mode/knob taps don’t fight scroll unfairly.  
7. Matches stated archetype slot map.  
8. **Red-team:** remove the preview widget in your head — if the face still communicates every param, the preview was decorative → FAIL.

---

## Related

- Component samples: [daw_elements.svg](../architecture/daw_elements.svg)  
- Strip chrome: [device_strip_chrome.md](device_strip_chrome.md)  
- Mobile shell: [mobile_ui_guidelines.md](../guidelines/mobile_ui_guidelines.md)  
- Tokens: `DeviceStripTheme`, `DevicePanelTheme` in Flutter  
- Reference layout: `FilterSectionLayout` (`panels/filter_section_layout.dart`)
