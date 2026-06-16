# Mobile UI Guidelines

## Visual direction

- Clean, modern, flat
- Functional first — inspired by Ableton/Bitwig workflow, not skeuomorphic
- Dark theme default for DAW context

## Core surfaces

1. **Arrangement / timeline** — tracks, clips, playhead
2. **Track headers** — names, selection
3. **Transport** — play, stop, BPM display
4. **Device strip** — horizontal chain at bottom
5. **Editors** — piano roll, sampler fullscreen (later)

## Gestures (target)

- Pinch zoom on timeline
- Drag clips and notes
- Long-press context actions
- Horizontal swipe on device strip

## Phone vs tablet

| Element | Phone | Tablet |
|---------|-------|--------|
| Device strip | Always visible bottom | Bottom or side |
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
