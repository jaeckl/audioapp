# Mobile UI Guidelines

## Visual direction

- Clean, modern, flat
- Functional first — inspired by Ableton/Bitwig workflow, not skeuomorphic
- Dark theme default for DAW context

## Core surfaces

1. **Arrangement / timeline** — tracks, clips, playhead
2. **Track headers** — names, selection
3. **Transport** — play, stop, BPM display
4. **Device strip** — horizontal chain at bottom (collapse on phone; fullscreen to edit)
5. **Editors** — piano roll, sampler fullscreen (later)

See [mobile_ux_competitive_analysis.md](mobile_ux_competitive_analysis.md) for Ableton Note / FL Studio Mobile layout research and target shell.

## Gestures (target)

- Pinch zoom on timeline
- Drag clips and notes
- Long-press context actions
- Horizontal swipe on device strip

## Device panels

- One **tab per parameter group** (Sample / Env / Filter / Level) — never all knobs at once.
- **Big rotary knobs** (`DeviceKnobSizes`: strip 56dp, editor 76dp).
- Double-tap knob resets to 50%; double-tap clip opens Duplicate / Delete menu.

## Phone vs tablet

| Element | Phone | Tablet |
|---------|-------|--------|
| Device strip | Collapsed peek on phone; expand for tabbed knobs | Bottom or side |
| Piano roll | Full-screen overlay | Split or overlay |
| Sample library | Modal / drawer | Panel |

## MVP placeholder shell

Milestone 00 delivers labeled regions without fake audio. Regions must map to future features clearly.

## System insets (edge-to-edge)

The DAW shell runs **edge-to-edge** on Android:

- `WindowCompat.setDecorFitsSystemWindows(false)` + Flutter `SystemUiMode.edgeToEdge`
- `windowLayoutInDisplayCutoutMode = shortEdges` so content may draw in punch-hole / inline camera areas in landscape
- **Do not** wrap the whole shell in `SafeArea` — it letterboxes above the gesture nav bar and beside cutouts

### Padding policy

| Region | Insets |
|--------|--------|
| Engine status header | Top status bar only (`ShellInsets.headerPadding`) |
| Arrangement / device strip | Full width; no horizontal safe-area padding |
| Transport | Flush to bottom display edge; no outer safe-area padding |

Fullscreen editors (piano roll, sampler) may apply additional per-control insets later.

See [US-00-03](../../tickets/milestone-00/US-00-03-edge-to-edge-shell-layout.md).
