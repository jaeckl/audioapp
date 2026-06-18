#!/usr/bin/env python3
"""Generate US-XX-YY-ux-ui.md and US-XX-YY-interaction.md companion tickets."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TICKETS = ROOT / "tickets"

# milestone_folder, id_suffix, title, parent_filename, status, ux dict, ix dict
FEATURES: list[dict] = [
    {
        "milestone": "milestone-00",
        "id": "00-02",
        "title": "DAW shell placeholder",
        "parent": "US-00-02-daw-shell-placeholder.md",
        "status": "Done",
        "ux": {
            "intent": "User immediately recognizes a DAW: timeline on top, transport at bottom, device strip when a track is selected.",
            "layout": "Three-band shell: arrangement (flex), device strip (fixed height bottom), transport (bottom inset). Dark flat theme.",
            "states": [
                ("Default", "Labeled regions even when empty; bridge status shows connection"),
                ("Track selected", "Device strip visible with placeholder device card"),
                ("No selection", "Strip hidden or shows hint"),
            ],
            "copy": ["Play", "Stop", "Add track", "Engine status line"],
            "ac": [
                "Regions identifiable without tutorial",
                "Dark theme consistent",
                "Widget tests cover layout",
            ],
        },
        "ix": {
            "entry": ["App launch"],
            "map": [
                ("Open app", "Launcher icon", "Splash → shell", "Shell visible"),
                ("Select placeholder track", "Track row tap", "Highlight", "Device strip shows"),
                ("Ping bridge", "Automatic on load", "Status shows connected", "pong in status"),
            ],
            "cancel": "N/A — no destructive flows",
            "errors": [("Bridge fail", "Red status / error text", "Shell still usable")],
            "demo": ["Launch → see three regions → tap track → strip appears"],
            "ac": ["Cold start < 3s to shell", "Track tap responsive"],
        },
    },
    {
        "milestone": "milestone-00",
        "id": "00-03",
        "title": "Edge-to-edge shell layout",
        "parent": "US-00-03-edge-to-edge-shell-layout.md",
        "status": "Done",
        "ux": {
            "intent": "Use full display — professional immersive DAW, not a letterboxed demo.",
            "layout": "Content bleeds to edges; only transport gets bottom gesture inset; header gets status bar inset.",
            "states": [
                ("Portrait", "No band above nav bar"),
                ("Landscape", "Timeline under cutout OK; controls remain tappable"),
            ],
            "copy": "No change to labels — spatial use of screen is the UX win",
            "ac": [
                "No letterboxing on Moto-class device",
                "Transport tappable above gesture bar",
            ],
        },
        "ix": {
            "entry": ["Rotate device", "Gesture nav"],
            "map": [
                ("Rotate portrait ↔ landscape", "Device rotation", "Reflow", "Full bleed maintained"),
                ("Navigate home gesture", "System gesture", "App backgrounds", "State preserved on return"),
            ],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Portrait full bleed → rotate landscape → cutout acceptable → transport still works"],
            "ac": ["Manual on physical device both orientations"],
        },
    },
    {
        "milestone": "milestone-01",
        "id": "01-01",
        "title": "Play hears engine audio",
        "parent": "US-01-01-play-hears-juce-audio.md",
        "status": "Done",
        "ux": {
            "intent": "Transport is the hero control — obvious play state.",
            "layout": "Play/Stop in transport bar; icon toggles (play triangle / stop square).",
            "states": [
                ("Stopped", "Play icon"),
                ("Playing", "Stop icon or active state"),
            ],
            "copy": ["Play", "Stop tooltips"],
            "ac": ["Playing state visible without audio", "Control in thumb zone"],
        },
        "ix": {
            "entry": ["Transport bar"],
            "map": [
                ("Start audio", "Play button", "Icon → Stop; optional status", "Tone audible"),
                ("Stop audio", "Stop button", "Icon → Play", "Silence immediate"),
            ],
            "cancel": "Stop always available while playing",
            "errors": [("Audio init fail", "Error in status area", "No fake playing state")],
            "demo": ["Play → hear tone → Stop → silence"],
            "ac": ["< 200ms perceived start", "Stop immediate"],
        },
    },
    {
        "milestone": "milestone-02",
        "id": "02-01",
        "title": "Add track",
        "parent": "US-02-01-add-track.md",
        "status": "Done",
        "ux": {
            "intent": "Adding tracks is frictionless — one obvious control.",
            "layout": "Add control in arrangement header/toolbar; new row appends to track list.",
            "states": [("Default", "Add icon/button visible"), ("After add", "New row with default name")],
            "copy": ["Add track tooltip"],
            "ac": ["New track visually distinct", "Name readable on phone"],
        },
        "ix": {
            "entry": ["Arrangement toolbar"],
            "map": [("Add track", "Toolbar button", "List updates", "Engine addTrack")],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Tap add → see Track N"],
            "ac": ["Single tap adds; no confirm dialog"],
        },
    },
    {
        "milestone": "milestone-02",
        "id": "02-02",
        "title": "Select track",
        "parent": "US-02-02-select-track.md",
        "status": "Done",
        "ux": {
            "intent": "Selection is obvious — drives device strip context.",
            "layout": "Selected row: accent border/background; strip appears below timeline.",
            "states": [("Unselected", "Neutral row"), ("Selected", "Accent + strip visible")],
            "copy": "Track name as primary label",
            "ac": ["Only one selected track", "Strip tied to selection"],
        },
        "ix": {
            "entry": ["Track row in arrangement"],
            "map": [("Select track", "Row tap", "Highlight + strip update", "selectTrack command")],
            "cancel": "Tap another track moves selection",
            "errors": [],
            "demo": ["Two tracks → tap each → strip follows"],
            "ac": ["Tap target full row height"],
        },
    },
    {
        "milestone": "milestone-02",
        "id": "02-03",
        "title": "Oscillator on device strip",
        "parent": "US-02-03-oscillator-device-strip.md",
        "status": "Done",
        "ux": {
            "intent": "Device strip feels like a hardware module — frequency is the star control.",
            "layout": "Horizontal card on strip: device name, frequency slider, value label (Hz).",
            "states": [("Default", "440 Hz or last value"), ("Dragging", "Live value label")],
            "copy": ["Oscillator", "Frequency", "Hz unit"],
            "ac": ["Slider usable one-handed", "Value readable"],
        },
        "ix": {
            "entry": ["Device strip when track selected"],
            "map": [
                ("Change frequency", "Slider drag", "Hz updates", "setDeviceParameter"),
                ("Hear change", "Play while adjusting", "Pitch changes", "Realtime DSP"),
            ],
            "cancel": "Release slider keeps value",
            "errors": [("Invalid param", "No UI change / error toast", "Prior value kept")],
            "demo": ["Slide low → Play → slide high → hear difference"],
            "ac": ["Slider does not fight strip scroll"],
        },
    },
    {
        "milestone": "milestone-03",
        "id": "03-01",
        "title": "Create MIDI clip",
        "parent": "US-03-01-create-midi-clip-on-timeline.md",
        "status": "Done",
        "ux": {
            "intent": "Clips read as musical regions on the grid.",
            "layout": "Clip block: rounded rect on timeline, width = length, label optional.",
            "states": [("No clips", "Empty timeline hint"), ("Has clip", "Colored block")],
            "copy": ["Add clip", "Add clip control on timeline"],
            "ac": ["Clip visible at correct beat width", "Tappable affordance"],
        },
        "ix": {
            "entry": ["Timeline with track selected"],
            "map": [("Create clip", "Add clip control", "Block appears", "createMidiClip")],
            "cancel": "N/A",
            "errors": [("No track selected", "Disabled or toast", "No orphan clip")],
            "demo": ["Select track → add clip → block on bar 1"],
            "ac": ["Clip tappable for editor (M04)"],
        },
    },
    {
        "milestone": "milestone-03",
        "id": "03-02",
        "title": "Transport playhead",
        "parent": "US-03-02-transport-playhead.md",
        "status": "Done",
        "ux": {
            "intent": "Playhead shows musical time — sync with transport.",
            "layout": "Vertical line or marker over timeline; BPM in transport.",
            "states": [("Stopped", "Playhead at start or held"), ("Playing", "Moving playhead")],
            "copy": ["BPM display e.g. 120"],
            "ac": ["Playhead visible on phone", "No full-tree flash each frame"],
        },
        "ix": {
            "entry": ["Play transport"],
            "map": [
                ("Play", "Transport", "Playhead moves", "advancePlayhead"),
                ("Stop", "Transport", "Playhead stops", "playing false"),
            ],
            "cancel": "Stop freezes position",
            "errors": [],
            "demo": ["Play 4 beats → watch playhead → Stop"],
            "ac": ["Smooth enough at 120 BPM"],
        },
    },
    {
        "milestone": "milestone-03",
        "id": "03-03",
        "title": "MIDI clip playback",
        "parent": "US-03-03-midi-clip-playback.md",
        "status": "Done",
        "ux": {
            "intent": "Hearing the clip is the payoff — UI stays minimal during play.",
            "layout": "No modal during playback; playhead + clip highlight optional.",
            "states": [("Playing", "Transport active"), ("Silent", "Stop state")],
            "copy": "None beyond transport",
            "ac": ["Audible on device speaker", "No silent success"],
        },
        "ix": {
            "entry": ["Play with clip on timeline"],
            "map": [("Play pattern", "Play", "Sound + playhead", "MIDI schedule")],
            "cancel": "Stop cuts audio immediately",
            "errors": [("Empty clip", "Silence or documented", "No crash")],
            "demo": ["Clip with notes → Play → hear pattern"],
            "ac": ["Loop region repeats if configured"],
        },
    },
    {
        "milestone": "milestone-04",
        "id": "04-01",
        "title": "Open piano roll",
        "parent": "US-04-01-open-piano-roll.md",
        "status": "Done",
        "ux": {
            "intent": "Editor feels focused — full attention on notes.",
            "layout": "Full-screen or near full-screen grid; pitch vertical, time horizontal; close top-left or back.",
            "states": [("Open", "Grid + notes"), ("Empty clip", "Grid only")],
            "copy": ["Close", "Piano roll title optional"],
            "ac": ["Scrollable on phone", "Close obvious"],
        },
        "ix": {
            "entry": ["Tap clip on timeline"],
            "map": [
                ("Open editor", "Clip tap", "Navigate to roll", "Load clip notes"),
                ("Close", "Close/back", "Return to arrangement", "State preserved"),
            ],
            "cancel": "Back returns without save prompt (auto-save via commands)",
            "errors": [],
            "demo": ["Tap clip → roll → close → timeline"],
            "ac": ["System back works"],
        },
    },
    {
        "milestone": "milestone-04",
        "id": "04-02",
        "title": "Add and delete notes",
        "parent": "US-04-02-add-delete-notes.md",
        "status": "Done",
        "ux": {
            "intent": "Notes are clear blocks on grid; empty cells invite tap.",
            "layout": "Note = rounded block; grid lines subtle; pitch labels on left.",
            "states": [("Note", "Filled block"), ("Empty cell", "Grid only")],
            "copy": "None",
            "ac": ["Min 44dp tap targets", "Note contrast on dark grid"],
        },
        "ix": {
            "entry": ["Piano roll open"],
            "map": [
                ("Add note", "Tap empty cell", "Block appears", "setMidiClipNotes"),
                ("Delete note", "Tap note", "Block removed", "setMidiClipNotes"),
            ],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Add 4 notes → delete 1 → Play"],
            "ac": ["Snap visible on add"],
        },
    },
    {
        "milestone": "milestone-04",
        "id": "04-03",
        "title": "Move and resize notes",
        "parent": "US-04-03-move-resize-notes-grid-snap.md",
        "status": "Done",
        "ux": {
            "intent": "Drag affordances — note lifts slightly when dragging.",
            "layout": "Resize handle at note end (right edge); drag body moves.",
            "states": [("Dragging", "Elevated note / ghost"), ("Snapped", "Aligns to grid")],
            "copy": "None",
            "ac": ["Drag does not break scroll", "Snap visually clear"],
        },
        "ix": {
            "entry": ["Note in piano roll"],
            "map": [
                ("Move", "Drag note body", "Follows finger; snap on release", "setMidiClipNotes"),
                ("Resize", "Drag end handle", "Length changes", "setMidiClipNotes"),
            ],
            "cancel": "Release commits; no revert gesture in MVP",
            "errors": [],
            "demo": ["Move note up → lengthen → Play"],
            "ac": ["One command per gesture end, not per pixel"],
        },
    },
    {
        "milestone": "milestone-04",
        "id": "04-11",
        "title": "Piano roll clip bounds & end marker",
        "parent": "US-04-11-piano-roll-horizontal-scroll-and-clip-bounds.md",
        "status": "Done",
        "ux": {
            "intent": "Clip end is obvious — red line + pill handle on ruler; editing canvas extends past it.",
            "layout": "Vertical red boundary at lengthBeats; 16×20 pill on ruler row; dimmed grid past boundary optional.",
            "states": [
                ("Default", "Boundary at clip length"),
                ("Dragging end", "Line follows finger; scroll locked"),
                ("Notes past end", "Full-opacity notes; silent on play"),
            ],
            "copy": "SnackBar on setClipLength failure",
            "ac": ["Handle visible without zoom", "Boundary aligns with grid beats"],
        },
        "ix": {
            "entry": ["Piano roll open on MIDI clip"],
            "map": [
                ("Resize clip", "Drag end pill", "Red line moves; release persists", "setClipLength"),
                ("Edit past end", "Draw note right of line", "Note appears", "setMidiClipNotes"),
                ("Play shortened", "Play transport", "Notes past boundary silent", "engine gate"),
            ],
            "cancel": "Drag away without release still commits on pointer up",
            "errors": [("setClipLength fail", "SnackBar + save error state", "Boundary reverts on reload")],
            "demo": ["Shorten to 2 bars → play → lengthen → play again"],
            "ac": ["One setClipLength per drag release", "28px hit target on marker"],
        },
    },
    {
        "milestone": "milestone-05",
        "id": "05-01",
        "title": "Save project",
        "parent": "US-05-01-save-project.md",
        "status": "Done",
        "ux": {
            "intent": "Save feels like any serious app — system dialog, clear success.",
            "layout": "Save icon in arrangement app bar; status line below or snackbar for result.",
            "states": [
                ("Idle", "Save icon enabled"),
                ("Success", "Saved project (green/neutral)"),
                ("Error", "Red error line"),
            ],
            "copy": ["Save project", "Saved project", "save_failed: …"],
            "ac": ["Error red visible", "Success not confused with error"],
        },
        "ix": {
            "entry": ["Save toolbar button"],
            "map": [
                ("Save", "Save tap", "SAF CreateDocument", "Zip written"),
                ("Cancel dialog", "System back", "No message", "No file"),
                ("Success", "Confirm location", "Saved project", "URI stored"),
            ],
            "cancel": "Dialog cancel → silent return",
            "errors": [("IO fail", "Red error text", "Project unchanged")],
            "demo": ["Save → pick file → see Saved project"],
            "ac": ["Default .audioapp.zip suggested"],
        },
    },
    {
        "milestone": "milestone-05",
        "id": "05-02",
        "title": "Load project",
        "parent": "US-05-02-load-project.md",
        "status": "Done",
        "ux": {
            "intent": "Load restores trust — user sees their tracks return.",
            "layout": "Load icon adjacent Save; same status/error area.",
            "states": [
                ("Success", "Loaded project"),
                ("Error", "load_failed message"),
                ("Loaded content", "Tracks/clips visible — not empty"),
            ],
            "copy": ["Load project", "Loaded project", "load_failed: …"],
            "ac": ["Never show success with empty arrangement when file had tracks"],
        },
        "ix": {
            "entry": ["Load toolbar button"],
            "map": [
                ("Load", "Load tap", "SAF OpenDocument", "Parse + snapshot"),
                ("Cancel", "Dialog cancel", "Silent", "Prior state"),
                ("Success", "Pick zip", "UI refresh + Loaded project", "Engine loaded"),
            ],
            "cancel": "Silent on cancel",
            "errors": [
                ("Bad zip", "Red error", "Prior state kept"),
                ("Empty parse bug", "MUST NOT happen — treat as error", "Prior state kept"),
            ],
            "demo": ["Save → kill app → Load → tracks back"],
            "ac": ["Round-trip on device"],
        },
    },
    {
        "milestone": "milestone-06",
        "id": "06-01",
        "title": "Bundled sample library",
        "parent": "US-06-01-bundled-sample-library.md",
        "status": "Todo",
        "ux": {
            "intent": "Library feels curated — starter pack ready on day one.",
            "layout": "Full-screen list or drawer: section Bundled / Imported; row = name + short preview icon.",
            "states": [
                ("List", "Scrollable samples"),
                ("Preview playing", "Row highlight or speaker icon active"),
                ("Empty imported", "Section hidden or empty state"),
            ],
            "copy": ["Sample library", "Starter pack", "Preview"],
            "ac": ["8+ bundled items visible", "Preview state obvious"],
        },
        "ix": {
            "entry": ["Library button from shell or strip"],
            "map": [
                ("Open library", "Menu/button", "Navigate", "List loads"),
                ("Preview", "Row tap or preview btn", "Audio audition", "Short play"),
                ("Insert on track", "Button on row", "Returns to arrangement", "US-06-03 when wired"),
                ("Close", "Back", "Return", "Stop preview"),
            ],
            "cancel": "Back stops preview",
            "errors": [("Preview fail", "Toast", "List still usable")],
            "demo": ["Open → preview kick → preview snare"],
            "ac": ["Preview < 2s start"],
        },
    },
    {
        "milestone": "milestone-06",
        "id": "06-02",
        "title": "Import sample",
        "parent": "US-06-02-import-sample-system-picker.md",
        "status": "Todo",
        "ux": {
            "intent": "Import is first-class — same weight as Save/Load.",
            "layout": "FAB or app bar Import in library; imported rows in separate section.",
            "states": [
                ("Importing", "Brief progress or spinner"),
                ("Imported", "Row with filename"),
                ("Error", "Red banner in library"),
            ],
            "copy": ["Import", "Imported", "Could not import file"],
            "ac": ["Imported visually distinct from bundled"],
        },
        "ix": {
            "entry": ["Library → Import"],
            "map": [
                ("Import", "Import tap", "SAF OpenDocument", "Register sample"),
                ("Cancel", "Dialog cancel", "Silent", "List unchanged"),
                ("Success", "Pick audio", "Row in Imported", "Stable ID"),
            ],
            "cancel": "Silent",
            "errors": [("Unsupported", "Error message", "No partial row")],
            "demo": ["Import WAV → appears → preview"],
            "ac": ["MIME filter + */* fallback"],
        },
    },
    {
        "milestone": "milestone-06",
        "id": "06-03",
        "title": "Insert sample clip on track",
        "parent": "US-06-03-insert-sample-clip-on-track.md",
        "status": "Todo",
        "ux": {
            "intent": "Inserting audio feels like placing a region — clear clip block on timeline.",
            "layout": "Library row action Insert on track; timeline shows sample clip distinct from MIDI (color/icon).",
            "states": [
                ("No clip", "Timeline empty or MIDI only"),
                ("Sample clip", "Block with name label"),
            ],
            "copy": ["Insert on track", "Sample clip"],
            "ac": ["Clip visually distinct from MIDI", "Sample name visible"],
        },
        "ix": {
            "entry": ["Sample library with track selected"],
            "map": [
                ("Insert", "Insert on track", "Clip on timeline", "createSampleClip"),
                ("Wrong track", "Select track first", "Toast if none", "No orphan clip"),
            ],
            "cancel": "Back from library without insert",
            "errors": [("No track selected", "Toast", "No clip created")],
            "demo": ["Select track → library → insert kick → clip appears"],
            "ac": ["≤3 taps from library to clip visible"],
        },
    },
    {
        "milestone": "milestone-06",
        "id": "06-04",
        "title": "Waveform in arrangement",
        "parent": "US-06-04-waveform-in-arrangement.md",
        "status": "Todo",
        "ux": {
            "intent": "Waveform makes clips recognizable at a glance.",
            "layout": "Mini waveform drawn inside clip rect; peaks centered vertically.",
            "states": [
                ("Sample clip", "Waveform visible"),
                ("MIDI clip", "No waveform"),
                ("Loading peaks", "Placeholder shimmer optional"),
            ],
            "copy": "None on clip",
            "ac": ["Kick vs snare visually different", "Readable on 1-bar clip width"],
        },
        "ix": {
            "entry": ["View arrangement after insert"],
            "map": [
                ("Scroll timeline", "Horizontal scroll", "Waveform scrolls with clip", "Cached peaks"),
            ],
            "cancel": "N/A",
            "errors": [("Missing peaks", "Flat fallback", "Clip still visible")],
            "demo": ["Two clips → different shapes"],
            "ac": ["No jank scrolling 2+ clips"],
        },
    },
    {
        "milestone": "milestone-06",
        "id": "06-05",
        "title": "Playhead sample audition",
        "parent": "US-06-05-playhead-sample-audition.md",
        "status": "Todo",
        "ux": {
            "intent": "Playhead crossing a clip should feel causal — sound follows the cursor.",
            "layout": "Selected track highlighted; optional clip highlight when playhead inside.",
            "states": [
                ("Playing inside clip", "Clip optional accent"),
                ("Playing outside", "Silent for samples"),
            ],
            "copy": "None",
            "ac": ["Selected track obvious during play"],
        },
        "ix": {
            "entry": ["Play transport with sample clips on selected track"],
            "map": [
                ("Play through clip", "Play", "Sample audible", "Schedule by playhead"),
                ("Stop", "Stop", "Silence", "Stop voices"),
                ("Select other track", "Track tap", "Audition follows selection", "selectedTrackId"),
            ],
            "cancel": "Stop",
            "errors": [("Decode fail", "Toast on play", "No crash")],
            "demo": ["Kick bar1 snare bar2 → Play → hear sequence"],
            "ac": ["Hear each clip as playhead enters"],
        },
    },
    {
        "milestone": "milestone-07",
        "id": "07-01",
        "title": "Open fullscreen sampler",
        "parent": "US-07-01-open-fullscreen-sampler.md",
        "status": "Todo",
        "ux": {
            "intent": "Fullscreen = focus mode for one sound.",
            "layout": "Edge-to-edge; sample title top; waveform area center; actions bottom.",
            "states": [("Open", "Fullscreen route"), ("Closing", "Transition back")],
            "copy": ["Sampler title", "Sample name as title"],
            "ac": ["Matches edge-to-edge rules", "Back visible"],
        },
        "ix": {
            "entry": ["Tap sampler card on strip"],
            "map": [
                ("Open", "Card tap", "Fullscreen route", "Load sample meta"),
                ("Close", "Back/close", "Pop to shell", "Trim preserved"),
            ],
            "cancel": "Back discards unsaved trim if applicable — document",
            "errors": [],
            "demo": ["Strip → fullscreen → back"],
            "ac": ["System back"],
        },
    },
    {
        "milestone": "milestone-07",
        "id": "07-02",
        "title": "Waveform trim editor",
        "parent": "US-07-02-waveform-trim-editor.md",
        "status": "Todo",
        "ux": {
            "intent": "Waveform makes trim trustworthy — PO required visual.",
            "layout": "Waveform full width; trim handles at start/end; Preview button; time labels.",
            "states": [
                ("Default", "Full waveform"),
                ("Trimmed region", "Highlighted window"),
                ("Preview", "Playing indicator"),
            ],
            "copy": ["Preview", "Start", "End"],
            "ac": ["Handles ≥ 48dp touch", "Waveform readable on AMOLED"],
        },
        "ix": {
            "entry": ["Fullscreen sampler"],
            "map": [
                ("Adjust start", "Drag left handle", "Region updates", "Trim param"),
                ("Adjust end", "Drag right handle", "Region updates", "Trim param"),
                ("Preview", "Preview btn", "Hear slice", "Offline preview"),
            ],
            "cancel": "Back saves trim to engine (auto-commit OK)",
            "errors": [("Preview fail", "Toast", "Handles still work")],
            "demo": ["Trim long sample → Preview → Play in arrangement"],
            "ac": ["Handles don't overlap illegally"],
        },
    },
    {
        "milestone": "milestone-08",
        "id": "08-01",
        "title": "Gain device",
        "parent": "US-08-01-gain-device.md",
        "status": "Todo",
        "ux": {
            "intent": "Gain reads as mixing fader — simple vertical or horizontal slider.",
            "layout": "Effect card on strip after instrument; dB or % label.",
            "states": [("Unity", "0 dB marker"), ("Boost/cut", "Value label")],
            "copy": ["Gain", "dB"],
            "ac": ["Clipping warning optional at extreme boost"],
        },
        "ix": {
            "entry": ["Add effect → Gain"],
            "map": [("Adjust gain", "Slider", "Label updates", "setDeviceParameter")],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Boost → Play → louder"],
            "ac": ["Audible on device"],
        },
    },
    {
        "milestone": "milestone-08",
        "id": "08-02",
        "title": "Pan device",
        "parent": "US-08-02-pan-device.md",
        "status": "Todo",
        "ux": {
            "intent": "Pan is symmetric — center detent obvious.",
            "layout": "Knob or slider with L/C/R labels.",
            "states": [("Center", "Detent"), ("L/R", "Label shows value")],
            "copy": ["Pan", "L", "R"],
            "ac": ["Headphones recommended for demo"],
        },
        "ix": {
            "entry": ["Add Pan effect"],
            "map": [("Pan", "Slider/knob", "L/R shift audible", "parameter")],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Hard L → hard R on headphones"],
            "ac": [],
        },
    },
    {
        "milestone": "milestone-08",
        "id": "08-03",
        "title": "Filter device",
        "parent": "US-08-03-filter-device.md",
        "status": "Todo",
        "ux": {
            "intent": "Cutoff sweep is intuitive — one primary slider.",
            "layout": "Filter card; cutoff slider; optional small curve hint.",
            "states": [("Open", "Bright"), ("Closed", "Dark")],
            "copy": ["Filter", "Cutoff", "Hz"],
            "ac": ["Sweep smooth in UI"],
        },
        "ix": {
            "entry": ["Add Filter"],
            "map": [("Sweep cutoff", "Slider", "Timbre changes on Play", "parameter")],
            "cancel": "N/A",
            "errors": [],
            "demo": ["Sweep down while playing"],
            "ac": [],
        },
    },
    {
        "milestone": "milestone-08",
        "id": "08-04",
        "title": "Parameter automation",
        "parent": "US-08-04-parameter-automation.md",
        "status": "Todo",
        "ux": {
            "intent": "Automation visible — lane or breakpoint dots on timeline or parameter panel.",
            "layout": "Simple lane under clip or automation panel; breakpoints draggable.",
            "states": [("Editing", "Breakpoints visible"), ("Playing", "Playhead crosses breakpoints")],
            "copy": ["Automate", "Automation"],
            "ac": ["MVP simple UI — not hidden in menu only"],
        },
        "ix": {
            "entry": ["Parameter menu → Automate"],
            "map": [
                ("Add breakpoint", "Tap lane", "Dot appears", "Write automation"),
                ("Move breakpoint", "Drag", "Value changes", "Update"),
                ("Play", "Transport", "Hear sweep", "Evaluate automation"),
            ],
            "cancel": "Delete breakpoint tap",
            "errors": [],
            "demo": ["Automate filter cutoff → Play sweep"],
            "ac": ["Save/load restores breakpoints"],
        },
    },
    {
        "milestone": "milestone-09",
        "id": "09-02",
        "title": "Export WAV",
        "parent": "US-09-02-export-wav-system-dialog.md",
        "status": "Todo",
        "ux": {
            "intent": "Export is a deliverable — progress then success like Save.",
            "layout": "Export in app bar; modal or inline progress; success message with filename.",
            "states": [
                ("Rendering", "Progress bar or spinner + %"),
                ("Success", "Export complete"),
                ("Error", "Red message"),
            ],
            "copy": ["Export", "Rendering…", "Export complete", "Export failed"],
            "ac": ["Progress during long render", "Cancel render optional"],
        },
        "ix": {
            "entry": ["Export button"],
            "map": [
                ("Export", "Tap", "Render offline", "Progress updates"),
                ("Save file", "SAF CreateDocument", "WAV written", "Success"),
                ("Cancel dialog", "Back", "No file", "Render may cancel"),
            ],
            "cancel": "Dialog cancel after render discards or saves to cache — document",
            "errors": [("Disk full", "Error message", "No corrupt WAV")],
            "demo": ["Export → save mybeat.wav → open externally"],
            "ac": ["Default .wav name", "MIME audio/wav"],
        },
    },
    {
        "milestone": "milestone-15",
        "id": "15-01",
        "title": "Device strip chrome framework",
        "parent": "US-15-01-device-strip-chrome-framework.md",
        "status": "Todo",
        "ux": {
            "intent": "Strip chrome is composable — each device family gets the right input/output columns without one-size Pan+Gain.",
            "layout": "Row: Tool | Mod? | Lfo? | Input? | Card | Output?; radii attach input/output to card edges.",
            "states": [
                ("Synth", "Stereo Pan + Gain output only"),
                ("Mono drum", "DrumMonoOutputPanel — Gain + Vel sens, no Pan"),
                ("Dynamics", "Input meter left, Gain + GR right"),
            ],
            "copy": ["Gain", "Pan", "Vel sens", "GR"],
            "ac": [
                "Slot width includes per-type input/output columns",
                "Card border radius meets input/output panels",
                "No DeviceLevelPanel hard-coded in slot",
            ],
        },
        "ix": {
            "entry": ["Expand device in chain"],
            "map": [
                ("Expand synth", "Tap slot", "Pan + Gain on right", "Stereo output rail"),
                ("Expand compressor", "Tap slot", "Input column + GR output", "Dynamics chrome"),
                ("Toggle mod strip", "Mod button", "Input/output stay aligned", "Chrome stable"),
            ],
            "cancel": "Collapse slot — chrome hidden with card",
            "errors": [],
            "demo": ["Synth vs compressor — different strip columns visible"],
            "ac": ["Registry returns correct panels per device type"],
        },
    },
    {
        "milestone": "milestone-15",
        "id": "15-02",
        "title": "Kick bench layout + kickModel engine branch",
        "parent": "US-15-02-kick-bench-kick-model.md",
        "status": "Todo",
        "ux": {
            "intent": "One-screen kick shaping — preview, model picker, all knobs — no tab hunting.",
            "layout": "~480px card: left 2/3 preview + 1/3 model segment (808/909/Analog); right 2×3 knob grid.",
            "states": [
                ("808 active", "All knobs live; preview animates on drag"),
                ("909/Analog", "Segment visible; disabled in v1"),
                ("Output rail", "Gain + Vel sens off-card (US-15-03)"),
            ],
            "copy": ["808", "909", "Analog", "Pitch", "Punch", "Tone", "Click", "Decay"],
            "ac": [
                "No tabs on kick card",
                "Preview ~2/3 left column height",
                "Six 808 params visible without tab tap",
            ],
        },
        "ix": {
            "entry": ["Insert Kick Generator → expand slot"],
            "map": [
                ("Tweak Pitch", "Drag knob", "Preview pitch curve updates", "Deeper/higher kick"),
                ("Raise Click", "Drag knob", "Transient preview", "Sharper attack"),
                ("Select 808", "Tap segment", "808 highlighted", "kickModel=0"),
                ("Save project", "Save", "Layout unchanged on reload", "Round-trip"),
            ],
            "cancel": "Remove device — bench dismissed",
            "errors": [],
            "demo": ["All knobs visible → tweak punch/decay → save/reload"],
            "ac": ["kickModel in JSON; hear timbre change on timeline"],
        },
    },
    {
        "milestone": "milestone-15",
        "id": "15-03",
        "title": "Mono drum output panels",
        "parent": "US-15-03-mono-drum-output-panels.md",
        "status": "Todo",
        "ux": {
            "intent": "Mono drums use Gain + Velocity sensitivity — not Pan — matching hardware drum strips.",
            "layout": "Compact right column ~56px: Vel sens + Gain knobs; no Pan.",
            "states": [
                ("Kick", "kickVelocity + gain"),
                ("Snare/clap/cymbal", "Type-specific *Velocity param + gain"),
            ],
            "copy": ["Gain", "Vel sens", "Velocity"],
            "ac": [
                "Pan not shown for any of four drum types",
                "Knobs meet 44dp touch target",
                "Automation/mod hooks on output knobs",
            ],
        },
        "ix": {
            "entry": ["Expand kick/snare/clap/cymbal slot"],
            "map": [
                ("Lower Gain", "Drag Gain", "Quieter hits", "gain param updated"),
                ("Vel sens 0%", "Drag Vel sens", "Pads same level", "Velocity ignored"),
                ("Vel sens 100%", "Drag Vel sens", "Harder pad = louder", "Velocity scales hit"),
                ("Save", "Save project", "Gain + Vel sens restored", "Round-trip"),
            ],
            "cancel": "Collapse slot",
            "errors": [],
            "demo": ["Kick Gain 50% → Vel sens sweep on pads → save/reload"],
            "ac": ["All four drum types share DrumMonoOutputPanel layout"],
        },
    },
    {
        "milestone": "milestone-15",
        "id": "15-04",
        "title": "Dynamics input and output panels",
        "parent": "US-15-04-dynamics-input-output-panels.md",
        "status": "Todo",
        "ux": {
            "intent": "Dynamics FX read like a rack — input level before, gain reduction after.",
            "layout": "Input column ~56–72px left of card; output ~72px with Gain + GR meter/bar.",
            "states": [
                ("Idle", "GR at 0 dB or empty bar"),
                ("Compressing", "GR shows reduction during signal"),
                ("Input", "Peak/RMS bar or envelope-driven v1"),
            ],
            "copy": ["GR", "Gain", "In", "dB"],
            "ac": [
                "All four dynamics types show input + output columns",
                "GR readable at strip height",
                "Pan not shown on dynamics devices",
            ],
        },
        "ix": {
            "entry": ["Insert gate/compressor/expander/limiter → expand"],
            "map": [
                ("Play loop", "Transport", "Input meter moves", "Signal visible pre-FX"),
                ("Lower threshold", "Drag on card", "GR increases on hits", "Compression audible"),
                ("Trim output Gain", "Drag output Gain", "Level post-FX changes", "Make-up gain"),
            ],
            "cancel": "Collapse slot",
            "errors": [],
            "demo": ["Kick → compressor → threshold down → GR moves → output Gain trim"],
            "ac": ["Slot width includes input + output for dynamics"],
        },
    },
]


def fmt_states(states: list[tuple[str, str]]) -> str:
    lines = ["| State | Treatment |", "|-------|-----------|"]
    for s, t in states:
        lines.append(f"| {s} | {t} |")
    return "\n".join(lines)


def fmt_map(rows: list[tuple]) -> str:
    lines = [
        "| User action | Control | Feedback | Result |",
        "|-------------|---------|----------|--------|",
    ]
    for row in rows:
        lines.append(f"| {row[0]} | {row[1]} | {row[2]} | {row[3]} |")
    return "\n".join(lines)


def fmt_errors(errors: list[tuple]) -> str:
    if not errors:
        return "_None beyond parent feature._"
    lines = ["| Failure | User sees | Data state |", "|---------|-----------|------------|"]
    for e in errors:
        lines.append(f"| {e[0]} | {e[1]} | {e[2]} |")
    return "\n".join(lines)


def fmt_list(items) -> str:
    if isinstance(items, str):
        return items
    return "\n".join(f"- {x}" for x in items)


def write_ux(f: dict) -> None:
    ux = f["ux"]
    mid = f["milestone"]
    sid = f["id"]
    path = TICKETS / mid / f"US-{sid}-ux-ui.md"
    content = f"""# US-{sid}-ux-ui: {f['title']} — UX & UI

## Type

UX / UI

## Parent feature

[US-{sid}]({f['parent']})

## Design intent

{ux['intent']}

## Layout & hierarchy

{ux['layout']}

## Visual states

{fmt_states(ux['states'])}

## Copy & feedback

{fmt_list(ux['copy'])}

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

{chr(10).join('- [ ] ' + a if f['status'] == 'Todo' else '- [x] ' + a for a in ux['ac'])}

## Status

**{f['status']}**
"""
    path.write_text(content, encoding="utf-8")


def write_ix(f: dict) -> None:
    ix = f["ix"]
    mid = f["milestone"]
    sid = f["id"]
    path = TICKETS / mid / f"US-{sid}-interaction.md"
    ac_prefix = "- [ ] " if f["status"] == "Todo" else "- [x] "
    content = f"""# US-{sid}-interaction: {f['title']} — Interaction

## Type

Interaction

## Parent feature

[US-{sid}]({f['parent']})

## Entry points

{fmt_list(ix['entry'])}

## Interaction map

{fmt_map(ix['map'])}

## System dialogs

_Per parent feature and ADR-0006. Document SAF MIME types in parent Platform UX._

## Cancel & back

{ix['cancel']}

## Error paths

{fmt_errors(ix['errors'])}

## Demo script (interaction-only)

{fmt_list(ix['demo'])}

## Acceptance criteria

{ac_prefix}{ix['ac'][0] if ix['ac'] else 'All interaction map rows verified on device'}
{''.join(ac_prefix + a for a in ix['ac'][1:])}

## Status

**{f['status']}**
"""
    path.write_text(content, encoding="utf-8")


def patch_parent(f: dict) -> None:
    parent_path = TICKETS / f["milestone"] / f["parent"]
    if not parent_path.exists():
        return
    text = parent_path.read_text(encoding="utf-8")
    block = (
        f"\n## Companion stories\n\n"
        f"- [UX/UI](US-{f['id']}-ux-ui.md)\n"
        f"- [Interaction](US-{f['id']}-interaction.md)\n"
    )
    if "## Companion stories" in text:
        return
    # Insert before ## Status
    if "## Status" in text:
        text = text.replace("## Status", block + "\n## Status", 1)
    else:
        text += block
    parent_path.write_text(text, encoding="utf-8")


def main() -> None:
    for f in FEATURES:
        write_ux(f)
        write_ix(f)
        patch_parent(f)
    print(f"Generated {len(FEATURES) * 2} companion tickets for {len(FEATURES)} features.")


if __name__ == "__main__":
    main()
