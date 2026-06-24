# Feature Brief – Library UI Improvements

> **STATUS: SUPERSEDED** — This design predates `library-ui-refinements/` (commit `51e6388`). The refinements feature implements preview playback, MIDI live play, and preset preview bar, but through a different approach. This doc is kept for reference only.

**Goal**: Align the audio library UI with the new UX guidelines by making preview widgets compact, showing real clip previews for MIDI and automation items, adding a global preview‑play button, providing a quick‑filter list of device presets, and separating selection from insertion.

**Scope**:
- UI changes limited to the Flutter front‑end (`app_flutter/`).
- No changes to the audio engine logic, only bridge callbacks for preview playback.
- All changes must be backward compatible with existing library data structures.

**Success Criteria**:
1. Sample preview widgets shrink uniformly across all item types.
2. MIDI items display a waveform clip preview instead of a note‑count badge.
3. Automation items display a miniature clip preview instead of a generic icon.
4. Every non‑automation item shows a play‑preview button; pressing it plays a short preview without inserting.
5. A “Presets” sub‑list appears in the left rail, filtering devices quickly.
6. Clicking an item only selects it; a global “Insert” button in the page header inserts the selected item.

**Constraints**:
- Must use existing `juce::JSON` for any new data contracts.
- UI must remain responsive on mobile (Flutter) and respect the existing theming.
- No direct modification of native bridge logic beyond adding a preview callback.
