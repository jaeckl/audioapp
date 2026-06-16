# AGENT.md — Mobile Clip-Launcher DAW

You are working on a new mobile DAW project.

The app is a **native mobile DAW** with a **Flutter UI** and a **JUCE/C++ realtime audio engine**. It is not a web app and not a client-server product. There is no backend server in the MVP. The term “backend” in this project means the local native audio engine and project engine.

The product direction is a **semi-professional mobile DAW** inspired by Ableton Live and Bitwig Studio, with a clean modern flat UI and an iconic bottom device strip. The first target platform is **Android only**, developed resource-efficiently. iOS is planned later but is not required for MVP. Avoid iOS-specific work unless explicitly requested.

The app must be developed through **visible vertical slices**. Do not make backend-only or engine-only progress that cannot be exercised from the Flutter UI. Every milestone must result in something playable, visible, testable, and usable from the app.

---

## 1. Product Vision

Build a mobile/tablet DAW focused on:

* loop-based production
* a timeline/arrangement-first MVP
* MIDI clips routed into devices on a bottom device strip
* simple built-in instruments and effects
* clean architecture that can later support clip launching, more device types, automation, sample editing, audio clips, and iOS

The MVP should allow the user to:

1. Open the app.
2. Create or load a local project.
3. Add a track.
4. See the track in the arrangement/timeline.
5. Add a MIDI clip to the track.
6. Select the track or clip.
7. See the bottom device strip.
8. Add or view a simple instrument device, such as a sampler or oscillator.
9. Route the MIDI clip through the device strip.
10. Press play and hear sound from the JUCE engine.
11. Save/load the diffable project.
12. Eventually render/export offline faster than realtime.

The app should feel like a minimal but real DAW, not a toy sequencer and not a fake UI prototype.

---

## 2. Non-Negotiable Rules

### 2.1 No fake audio

Never fake audio functionality with UI-only mocks.

A story is not complete if it only creates Flutter widgets but does not connect to the native audio/project engine when audio behavior is involved.

Every audio-related milestone must include a real playable path through JUCE.

### 2.2 No desktop plugin formats

Do not implement, scaffold, or plan around desktop plugin hosting.

Explicitly unsupported:

* VST
* VST3
* LV2
* CLAP
* AAX
* desktop AudioUnit hosting

The app’s “plugins” are internal built-in **devices**. Devices may be expanded across app versions and may later be sold/unlocked through in-app purchases, but they are not external native libraries downloaded and loaded at runtime.

### 2.3 Realtime safety from day one

The realtime audio thread must follow realtime-safe rules:

* no heap allocation
* no locks/mutex waits
* no file I/O
* no logging
* no Flutter/Dart calls
* no blocking system calls
* no waiting on futures/promises
* no unbounded graph mutation directly on the audio thread
* no dynamic memory growth during audio callback
* no string parsing
* no JSON parsing
* no UI access
* no platform channel calls

Use preallocated buffers, command queues, immutable graph snapshots, double buffering, or other realtime-safe patterns.

### 2.4 Resource efficiency

This is a mobile DAW. RAM and CPU efficiency matter.

Prefer:

* compact project state
* bounded memory usage
* explicit buffer ownership
* pooling where justified
* lazy sample loading
* sample streaming later if needed
* avoiding large temporary allocations
* avoiding unnecessary object churn in Dart and C++
* avoiding expensive UI rebuilds during playback
* carefully throttled state updates from engine to UI

Do not introduce large frameworks or architecture layers unless they solve a clear problem.

### 2.5 Visible vertical slices only

Do not spend multiple milestones on hidden architecture without producing a working, visible app slice.

Each milestone must answer:

* What can the user now do?
* What can the user see?
* What can the user hear?
* How is it tested?
* Which docs/tickets were updated?

### 2.6 Use JUCE and platform primitives — do not reinvent the wheel

This project is built on **JUCE** and **mobile OS APIs**. Agents must prefer established libraries over custom implementations.

**JSON and serialization (C++):**

* Use **`juce::JSON`**, **`juce::var`**, and **`juce::DynamicObject`** for reading/writing `project.json` and other structured config.
* Do **not** implement hand-rolled JSON parsers, `find("\"key\":")` scanners, or ad-hoc string builders for persisted formats.
* Parsing/serialization runs on the **control thread only** (never on the audio callback — see §2.3).
* Pretty-printed output is fine; use a real parser that handles whitespace.

**Other JUCE:**

* Before adding a utility (files, strings, time, threading helpers), check whether `juce_core` or an already-linked module provides it.
* Add new JUCE modules only when justified; document in [juce_dependency.md](docs/architecture/juce_dependency.md).

**OS and Flutter:**

* User-facing **Save** / **Open** / **Export** must use **system document pickers** (Android SAF `CreateDocument` / `OpenDocument`, etc.), not folder-tree consent, raw path fields, or engine writing directly to arbitrary paths on mobile.
* Zip/archive assembly on Android belongs in the Kotlin OS bridge; C++ owns schema and bytes-to-json, not SAF.

**When custom code is OK:**

* Realtime DSP, graph scheduling, and domain types with no suitable JUCE equivalent.
* Thin adapters between JUCE types and bridge DTOs.

### 2.7 Complete vertical slices — aim for a “wow moment”

A user story is **not** done when only the engine hook exists, or when the happy path works only in unit tests with mocks.

Ship the **full PO slice in one pass**:

| Layer | Must be included when the story needs it |
|-------|------------------------------------------|
| **UX** | Obvious entry point (toolbar/menu), native dialogs where expected, status text, errors in the UI |
| **Engine** | Authoritative C++ state change + serialization if persistent |
| **Bridge** | Typed command, structured errors, snapshot refresh |
| **Tests** | C++ round-trip on **real** serialized output; Flutter/widget tests; **manual demo script** on device |

**Anti-patterns (do not ship as “done”):**

* Save/load that writes bytes but uses a broken parser → user sees empty project with no error.
* “Save” that only dumps JSON to an internal path without a save dialog.
* “Load” that only works from a dev fixture, not from the user’s picked file.
* Splitting one user-visible feature across multiple follow-up tickets (e.g. save dialog in a later amendment).

If a ticket’s acceptance criteria are too thin, **refine the ticket first** (§14), then implement.

**Demo script:** Every persistence or major UX story must name a **60-second on-device demo** (e.g. *add track → save via system dialog → kill app → open → load same file → arrangement matches*).

### 2.8 Ship with confidence — investor-quality increments

Treat **every increment as a demo to investors**: polished enough to trust, focused enough to ship.

**Be bold and clear:**

* Choose a concrete solution and implement the **full user-facing slice** — do not hedge with half-features that need a follow-up pass.
* Prefer one well-built path over multiple partial options.
* State goals and outcomes plainly in tickets and PRs.

**Do not overengineer:**

* No extra abstraction layers, generic frameworks, or “future-proof” plumbing without a current user story.
* No duplicate models (Flutter vs C++) or parallel parsers.
* If JUCE or the OS already solves it, use that.

**Think one step ahead:**

* **Modularity** — engine, bridge, and UI stay separable; devices and serialization evolve without rewrites.
* **Separation of concerns** — C++ owns truth; Flutter renders; Kotlin/Android owns SAF I/O.
* **Maintainability** — code a teammate can change in six months without archaeology.

**Quality bar (mobile first):**

* **No bugs, no strange behaviour** — empty states, cancel, and errors must be intentional and visible; never “success” with wrong data.
* **Mobile UX** — thumb reach, system dialogs, clear feedback, no desktop idioms on phone.
* **Verify on device** before calling a story done; C++ tests alone are not enough for persistence or SAF flows.

---

## 3. Target Platform

MVP target:

* Android
* mobile/tablet form factors
* Flutter UI
* JUCE/C++ native audio engine
* local project storage
* no server backend
* no cloud accounts
* no iOS build requirement in MVP

iOS:

* planned later
* architecture should not prevent iOS
* do not add iOS-specific code unless needed for clean abstraction
* do not block Android MVP on iOS setup

Desktop:

* not a target for MVP
* the C++ engine should be generic enough that reuse in a future desktop app remains possible

---

## 4. Architecture Overview

The project is a monorepo.

Recommended structure:

```text
/
  AGENT.md
  README.md
  docs/
    architecture/
    adr/
    milestones/
    guidelines/
    bridge/
    engine/
    ui/
    testing/
  tickets/
    milestone-00/
    milestone-01/
    milestone-02/
  app_flutter/
    lib/
    test/
    integration_test/
    android/
  engine_juce/
    CMakeLists.txt
    src/
    include/
    tests/
  native_bridge/
    android/
    include/
    src/
  fixtures/
    projects/
    samples/
  tools/
```

### 4.1 Flutter responsibility

Flutter owns:

* UI layout
* gestures
* visual editing interactions
* timeline rendering
* device strip rendering
* sample library browser UI
* project/session user interaction
* dispatching commands to the native engine
* displaying state received from the native engine

Flutter must not own realtime audio state.

Flutter must not directly generate audio for production features.

### 4.2 JUCE/C++ responsibility

JUCE/C++ owns:

* audio callback
* MIDI scheduling
* audio graph
* device graph
* transport
* project model authority
* clip playback
* sample loading and decoding
* instrument/effect DSP
* automation evaluation
* offline rendering
* project serialization core, unless explicitly split later

### 4.3 Authoritative project state

The authoritative project and audio graph state should live in C++.

Flutter receives snapshots/projections of that state for rendering and editing.

The UI sends commands such as:

* `createProject`
* `addTrack`
* `deleteTrack`
* `selectTrack`
* `addDeviceToTrack`
* `setDeviceParameter`
* `createMidiClip`
* `updateMidiClipNotes`
* `setClipLoopRegion`
* `play`
* `stop`
* `setBpm`
* `saveProject` — Flutter UI; Android Kotlin writes file, C++ serializes (ADR-0006)
* `loadProject` — Flutter UI; Android Kotlin reads file, C++ deserializes (ADR-0006)
* `renderProject`

Commands should be validated by the C++ project engine.

Flutter should not mutate a separate project model and hope it stays synchronized.

### 4.4 Bridge direction

Use a maintainable bridge that starts simple but does not violate realtime rules.

Recommended staged approach:

1. MVP bridge:

   * Flutter MethodChannel for commands.
   * Native-to-Flutter event stream for coarse state updates.
   * JSON is acceptable only for non-realtime setup and early prototyping, but avoid large or frequent JSON payloads.

2. Near-term bridge:

   * typed command/event schema
   * compact binary snapshots for larger state
   * generated bindings if useful
   * stable bridge API document

3. Long-term bridge:

   * commands remain asynchronous
   * high-frequency UI data is throttled
   * realtime audio thread communicates only with native control structures, never with Flutter directly

Important:

* MethodChannel is not realtime.
* Platform channels must never be used from the audio callback.
* UI state updates should be throttled, coalesced, and sent from a non-audio thread.
* Engine graph changes should be scheduled safely and applied at deterministic points.

Create and maintain:

```text
docs/bridge/flutter_native_bridge.md
```

This document must describe:

* command API
* event API
* thread ownership
* serialization format
* error handling
* versioning
* realtime safety rules
* examples

---

## 5. Audio Engine Design

The audio engine must be graph-based from the beginning.

However, do not overengineer. Start with a minimal graph that can later grow.

### 5.1 Graph concepts

Core concepts:

* Project
* Transport
* Timeline
* Track
* Clip
* Device
* DeviceChain
* AudioGraph
* MidiEventBuffer
* AudioBuffer
* AutomationSignal
* Parameter
* RoutingNode

Tracks are visually generic. A track may host:

* MIDI clips
* audio clips
* automation clips

Devices on the strip either:

* produce data/audio
* transform MIDI
* transform audio
* produce automation/control signals
* receive/send signals

The device strip is both instrument strip and effect strip.

A track’s clip data is routed through the track’s device chain.

### 5.2 Device model

Devices are internal built-in modules.

Initial device categories:

* Instrument devices
* Audio effects
* MIDI effects
* Utility/control devices
* Send/receive routing devices

MVP devices:

* Simple Oscillator Device
* Simple Sampler Device or Drum Sampler Device
* Gain Device
* Pan Device
* Simple Filter Device
* Delay or Reverb can come later unless trivial

Later devices:

* Drum sampler
* Subtractive synth
* Wavetable synth
* FM synth
* EQ
* Compressor
* Distortion
* Advanced modulation
* In-app-purchase device unlocks

Device design must include:

* stable device ID
* versioned device state
* parameter descriptors
* parameter values
* automation target IDs
* serialization
* UI metadata
* realtime-safe processing

### 5.3 Send/receive devices

Because the engine is graph-based, send/receive devices may be supported as internal routing devices.

Do not implement full bus/mixer complexity before the first playable slices.

If implemented early, keep it minimal:

* SendDevice routes a portion of signal to a named/internal bus.
* ReceiveDevice receives from that bus.
* Avoid feedback loops unless explicitly designed.
* Validate routing graph.
* Detect cycles.
* Ensure deterministic processing order.

### 5.4 Fixed BPM for MVP

MVP uses fixed BPM.

No tempo automation.
No tempo map.
No time signature changes.

Design should not make future tempo maps impossible.

---

## 6. Timeline, Clips, and Arrangement

MVP is timeline/arrangement-first.

Clip launching/session view is part of the product vision but not required in the first MVP unless explicitly reprioritized.

### 6.1 Arrangement MVP

The arrangement should support:

* tracks
* MIDI clips
* clip start position
* clip length
* looping by extending the clip region
* fixed BPM
* play/stop
* playhead display
* basic zoom/pan gestures on mobile

### 6.2 MIDI clips

MIDI clips should support mobile-friendly editing.

MVP MIDI editing should include:

* create note
* move note
* resize note
* delete note
* simple grid snapping
* playback through selected track’s device chain

Velocity, swing, advanced quantization, expression, MPE, and MIDI controller support are not required for MVP, but the model should not prevent them.

A piano roll is the primary MIDI editing surface. It must be mobile-friendly.

### 6.3 Audio clips

Audio clips are planned but not the first MVP priority unless needed for sample library workflows.

When introduced, use non-destructive editing:

* source media remains unchanged
* clips reference media file ID/path
* clips store start/end/offset/loop metadata
* destructive edits must create new media assets explicitly

---

## 7. Sample Library and Sampler

The app should include a sample library view.

MVP sample support:

* import or reference audio files from local storage
* show sample library
* select a sample
* load it into a sampler device
* trigger it from MIDI notes
* store project references to library samples

Project storage behavior:

* While working locally, projects may reference samples from the library.
* On export/project bundle, copy referenced samples into the exported bundle.
* Project files should remain diffable where possible.

Sampler fullscreen view:

* sample waveform display eventually
* trim start/end
* root note or pad assignment later
* slicing later
* destructive editing not required
* time-stretching/pitch-shifting not required early

---

## 8. Automation

Automation should be part of the architecture from the beginning.

MVP may include only simple parameter automation if feasible.

The model should allow:

* automation clips
* parameter target IDs
* automation lanes
* automation curves later
* automation routed as control signals

Do not let automation become hardcoded to Flutter widgets.

Automation is project data and must be serializable.

---

## 9. Project Format

The project format must be diffable and versioned.

Use a **`.audioapp.zip` archive** containing `project.json` and asset paths ([ADR-0005](../adr/ADR-0005-diffable-project-format.md)).

Recommended archive layout (inside `.audioapp.zip`):

```text
project.audioapp.zip
  project.json
  assets/samples/
  metadata/
```

`project.json` should be human-readable and diffable.

Project data should include:

* project format version
* app version that wrote it
* BPM
* tracks
* clips
* devices
* device parameters
* automation
* sample references
* routing
* stable IDs

Rules:

* Use stable IDs for tracks, clips, devices, parameters, samples, and automation targets.
* Include project file format version from the beginning.
* Keep migrations possible.
* Do not store large binary data inside JSON.
* Reference library samples during normal editing.
* Copy samples into exported bundles when exporting/sharing.
* No autosave in MVP unless explicitly requested.
* Undo/redo architecture should exist from day one.
* **Serialize/deserialize with `juce::JSON` / `juce::var`** on the control thread (§2.6). Do not maintain a parallel custom JSON implementation.

### 9.1 Undo/redo

Use command-based mutation where practical.

Commands should be representable as undoable operations:

* add track
* delete track
* create clip
* move clip
* edit MIDI note
* add device
* change parameter
* change routing

The architecture should not require every early command to have perfect undo in the first milestone, but it must not block undo/redo later.

---

## 10. UI/UX Direction

Style:

* clean
* modern
* flat
* functional first
* not skeuomorphic
* inspired by Ableton/Bitwig workflow
* mobile/tablet native interaction patterns
* gesture-heavy

MVP UI elements:

* main arrangement/timeline view
* track list/headers
* bottom transport
* bottom device strip
* simple device cards
* selected track/clip state
* basic piano roll or MIDI clip editor
* sample library view
* fullscreen sampler view later

Phone constraints:

* On phones, show at most what fits.
* Prioritize track area plus bottom device strip.
* Avoid desktop-style dense panels.
* Use adaptive layouts for tablet.
* Do not force desktop DAW UI onto mobile.

Tablet constraints:

* More panels can be visible.
* Arrangement + device strip + inspector/sample browser can coexist if space allows.

Gesture ideas:

* pinch to zoom timeline
* drag clips
* long press for context actions
* horizontal swipe device strip
* tap device to open fullscreen editor
* drag notes in piano roll
* two-finger pan where appropriate

Do not polish endlessly before the first playable slice.

---

## 11. Testing Requirements

Testing is required from the beginning.

Create tests for:

* C++ unit tests
* graph processing tests
* project serialization tests
* project migration tests once versions exist
* device parameter tests
* MIDI scheduling tests
* offline render/golden tests
* Flutter widget tests
* Flutter integration tests for core flows
* bridge command tests
* Android smoke tests

### 11.1 Audio golden tests

Add deterministic offline render tests where possible.

Examples:

* render simple oscillator for 1 bar and compare expected properties
* render MIDI note through sampler
* verify silence when stopped
* verify gain device changes amplitude
* verify pan/gain do not produce NaN
* verify graph output is deterministic

Do not rely only on human listening.

### 11.2 Performance budgets

Define and maintain performance budgets in:

```text
docs/testing/performance_budgets.md
```

Include budgets for:

* audio callback safety
* max allocations during playback
* graph rebuild behavior
* UI frame stability
* memory usage for sample loading
* offline render expectations
* acceptable state update frequency from engine to Flutter

Do not add code that knowingly violates these budgets without updating the docs and explaining why.

---

## 12. Development Workflow

Use a single main branch.

No complex branching workflow in MVP.

Rules:

* Work from local markdown tickets in `/tickets`.
* Create/update docs before major architectural changes.
* Keep changes small and vertical.
* Do not perform large rewrites without updating architecture docs first.
* Every ticket must define acceptance criteria.
* Every milestone must include tests.
* Every milestone must produce visible app behavior.
* Every completed ticket should update relevant docs if behavior or architecture changed.

Semantic versioning is used for app versions.

Additionally version:

* project file format
* bridge API
* engine graph/device API

---

## 13. Documentation Requirements

Before major implementation, create these docs:

```text
docs/architecture/overview.md
docs/architecture/realtime_audio_rules.md
docs/architecture/project_model.md
docs/architecture/audio_graph.md
docs/architecture/device_model.md
docs/bridge/flutter_native_bridge.md
docs/guidelines/cpp_guidelines.md
docs/guidelines/flutter_guidelines.md
docs/guidelines/mobile_ui_guidelines.md
docs/guidelines/testing_guidelines.md
docs/guidelines/git_workflow.md
docs/guidelines/versioning.md
docs/testing/performance_budgets.md
```

Create ADRs in:

```text
docs/adr/
```

Use ADRs for decisions such as:

* Flutter + JUCE architecture
* authoritative C++ project model
* bridge approach
* graph-based engine
* Android-first MVP
* no external plugin formats
* diffable project format
* local-only app MVP

ADR template:

```markdown
# ADR-000X: Title

## Status

Accepted / Proposed / Superseded

## Context

What problem are we solving?

## Decision

What did we decide?

## Consequences

What gets easier?
What gets harder?
What risks remain?
```

---

## 14. Ticket Format

All work must be planned as markdown tickets under `/tickets`.

Tickets are written for a **product owner**, not only for engineers. A PO should be able to read a ticket and know exactly what the user taps, what dialog appears, and how to verify success on a phone.

Ticket template:

```markdown
# TICKET-ID: Title

## Type

Feature / Spike / Refactor / Test / Documentation / Bug

## Milestone

Milestone name

## User story

As a **user**, I want … so that …

## Goal

One sentence: the “wow moment” when this ships.

## Background

Relevant context and links to docs/ADRs.

## UX flow

Numbered steps from the user’s perspective (every screen, button, and system dialog):

1. User taps …
2. System shows … (e.g. Android save-file dialog, default filename)
3. On success …
4. On cancel …
5. On error …

## Platform UX

| Platform | Requirement |
|----------|-------------|
| Android | e.g. SAF `CreateDocument`, MIME type, default name, persistable URI |
| (future iOS) | … |

## Scope

What is included in **this** slice (must be shippable alone).

## Out of scope

What is explicitly not included (other stories or later phases).

## Acceptance criteria

Functional (check all that apply):

- [ ] …
- [ ] Round-trip: created content survives save → reload (or named demo script)
- [ ] Cancel leaves prior state unchanged
- [ ] Failure shows clear message in UI (not silent empty state)
- [ ] Uses framework/platform primitives (JUCE JSON, system dialogs) per §2.6

## Demo script (on-device, ~60s)

Steps a PO runs to sign off:

1. …
2. …

## Tests required

- [ ] C++ unit tests (real serialization round-trip where applicable)
- [ ] Widget / integration tests
- [ ] Audio golden tests (if audio)
- [ ] Manual demo script on Android device

## User-visible result

What the user sees/hears when the story is complete.

## Realtime/performance notes

Any realtime or memory implications.

## Documentation updates

Which docs/ADRs must be updated?

## Depends on

Story IDs or none.

## Status

Todo / In progress / Done
```

---

## 15. Milestone Plan

### Milestone 00 — Project Bootstrap and Architecture Docs

Goal:

Create the monorepo structure, docs, initial tickets, and minimal build skeleton.

Must create:

* Flutter app skeleton
* JUCE/C++ engine skeleton
* Android native bridge skeleton
* docs listed above
* ADRs for major decisions
* ticket folders
* basic CI or local scripts where practical
* README with setup instructions

Acceptance criteria:

* App builds on Android.
* Native library skeleton builds or has clearly documented build steps.
* Docs exist.
* Tickets for Milestone 01 and 02 exist.
* No fake claims of audio functionality.

User-visible result:

* App opens to a placeholder DAW shell with transport/device strip placeholders.
* It is clear where timeline, track area, and bottom device strip will be.

---

### Milestone 01 — First Real Sound Through Flutter → JUCE

Goal:

Prove the complete vertical path:

Flutter UI button → native bridge command → JUCE engine → Android audio output.

Scope:

* Play/stop transport button in Flutter.
* JUCE outputs simple oscillator, click, or test tone.
* No full project model required yet.
* No MIDI clips required yet.
* No fake audio.

Acceptance criteria:

* Pressing Play in Flutter produces audible sound from JUCE.
* Pressing Stop stops sound.
* Audio thread follows realtime rules.
* No Flutter calls from audio thread.
* C++ test verifies oscillator output is non-silent.
* Flutter test verifies play/stop command dispatch.
* Bridge doc updated with actual command names.

User-visible result:

* User can open app, press play, and hear a real JUCE-generated sound.

---

### Milestone 02 — Minimal Project, Track, Device Strip

Goal:

Create the first DAW-like vertical slice.

Scope:

* C++ project model with one project.
* Add track command.
* Track visible in Flutter.
* Track selection.
* Bottom device strip visible.
* Add/show Simple Oscillator Device on selected track.
* Device parameter shown in Flutter.
* Basic parameter change from Flutter to C++.
* Play uses selected track/device graph.

Acceptance criteria:

* User can add a track.
* User can select a track.
* Bottom strip shows device chain for selected track.
* User can change at least one oscillator parameter.
* Sound changes according to the parameter.
* Project state is owned by C++ and reflected in Flutter.
* Basic serialization design documented.

User-visible result:

* User sees a real track and a real bottom device strip controlling real audio.

---

### Milestone 03 — MIDI Clip Playback

Goal:

Route MIDI clip data through the track’s device strip.

Scope:

* Create MIDI clip on track.
* Store MIDI notes in project model.
* Timeline displays clip.
* Playhead plays clip at fixed BPM.
* MIDI events route into Simple Oscillator Device or Simple Sampler Device.
* Clip looping by extending arrangement region.

Acceptance criteria:

* User can create a MIDI clip.
* Clip appears on the timeline.
* Clip contains at least one editable or generated note.
* Pressing Play schedules MIDI notes correctly.
* Device produces sound from MIDI input.
* Loop extension works.
* C++ tests cover MIDI scheduling.
* Flutter tests cover visible clip creation.

User-visible result:

* User can create a MIDI clip on a track and hear it play through the device strip.

---

### Milestone 04 — Mobile MIDI Editing

Goal:

Make MIDI clips useful on mobile.

Scope:

* Piano roll or mobile-friendly MIDI editor.
* Add/move/resize/delete note.
* Basic grid snapping.
* Clip editor opens from timeline.
* Notes update project engine state.
* Playback reflects edits.

Out of scope:

* velocity editing
* swing
* advanced quantization
* MIDI controllers
* MPE

Acceptance criteria:

* User can open MIDI clip editor.
* User can add a note.
* User can move a note.
* User can resize a note.
* User can delete a note.
* Playback reflects edits immediately or after a safe graph/state update.
* Tests cover note mutation and serialization.

User-visible result:

* User can write a simple melody or rhythm on mobile and hear it.

---

### Milestone 05 — Diffable Save/Load

Goal:

User can **save and open projects like a real app** — system dialogs, zip archive, full round-trip on device.

Scope (single shippable slice — not engine-only first):

* `.audioapp.zip` archive (`project.json` + folder layout per ADR-0005).
* **`juce::JSON` serialization** in C++ (no custom parser).
* Android SAF **save-file** and **open-file** dialogs (ADR-0006).
* Save / Load in app chrome with success, cancel, and error feedback.
* C++ archive round-trip tests + on-device demo script.

Acceptance criteria:

* Tap Save → system save dialog → default `project.audioapp.zip` → archive contains diffable `project.json` with current tracks/clips.
* Tap Load → system open dialog → arrangement and device strip match saved project.
* Kill app between save and load → still works.
* Cancel → no error, state unchanged.
* Corrupt/wrong file → clear error in UI.
* C++ tests parse **actual** `projectFileToJson` output.

User-visible result:

* PO demo: add track + clip → Save → force-stop app → Load → continue editing. One pass, no follow-up “add dialog” ticket.

---

### Milestone 06 — Sample Library and Simple Sampler

Goal:

Introduce sample-based workflow.

Scope:

* Sample library view in Flutter.
* Import/reference local audio sample.
* Simple Sampler Device.
* Load sample into sampler.
* Trigger sample from MIDI notes.
* Basic sample metadata.
* Project references sample path/library ID.

Out of scope:

* time-stretching
* pitch-shifting
* slicing
* destructive editing

Acceptance criteria:

* User can browse/select a sample.
* User can load sample into sampler device.
* MIDI clip triggers sample.
* Project stores sample reference.
* Missing sample handling is documented.
* Tests cover sampler triggering and project serialization.

User-visible result:

* User can make a simple sample-based loop.

---

### Milestone 07 — Fullscreen Sampler Editing

Goal:

Make the sampler feel like a real mobile device.

Scope:

* Tap sampler device to open fullscreen view.
* Show sample info and eventually waveform.
* Set trim start/end.
* Playback respects trim.
* Non-destructive metadata editing.

Acceptance criteria:

* User can open sampler fullscreen view.
* User can adjust sample start/end.
* Playback changes according to trim.
* Source file remains unchanged.
* Project stores trim metadata.

User-visible result:

* User can shape a sample without editing the original file.

---

### Milestone 08 — Basic Effects and Automation

Goal:

Add useful device-strip processing.

Scope:

* Gain Device
* Pan Device
* Filter Device
* simple parameter automation architecture
* automation clip/lane representation if feasible
* route automation to device parameter

Acceptance criteria:

* User can add effect device after instrument.
* User can change parameters.
* Audio output changes.
* Automation data can target a parameter.
* Tests cover parameter changes and automation evaluation.

User-visible result:

* User can shape sound through the device strip.

---

### Milestone 09 — Offline Render

Goal:

Render project to audio offline faster than realtime.

Scope:

* offline render engine path
* render current project to WAV or chosen default
* progress callback
* basic error handling
* render tests

Acceptance criteria:

* User can render/export project locally.
* Render uses engine graph.
* Render is deterministic for test projects.
* Export does not require realtime playback.
* Tests verify rendered output is non-silent for known project.

User-visible result:

* User can export a loop/project as an audio file.

---

## 16. Coding Guidelines

### 16.1 C++ guidelines

* Prefer modern C++.
* Keep realtime code simple and explicit.
* Avoid exceptions in realtime processing.
* Avoid RTTI-heavy designs in audio path.
* Avoid shared ownership in audio processing where possible.
* Prefer stable handles/IDs over raw cross-layer pointers.
* Separate project/control model from audio render model.
* Use immutable or double-buffered render graph snapshots.
* Keep device DSP independent from Flutter.
* Keep serialization independent from UI.
* **Use `juce::JSON` / `juce::var` for JSON** — never hand-roll parsers (§2.6).
* Write unit tests for engine logic; serialization tests must round-trip **real** engine output.

### 16.2 Flutter guidelines

* Keep widgets focused.
* Avoid rebuilding large timeline/device trees unnecessarily.
* Use explicit state models.
* Treat native engine as authoritative.
* Do not duplicate complex project rules in Dart.
* Use adaptive layouts for phone/tablet.
* Keep gestures predictable.
* Keep UI functional before polishing.
* Write widget tests for core flows.
* Use integration tests for bridge-driven flows where practical.

### 16.3 Bridge guidelines

* Commands must be explicit and typed.
* Events must be versioned.
* Errors must be structured.
* Bridge must document thread expectations.
* Do not send high-frequency unbounded updates to Flutter.
* Coalesce playhead/state updates.
* Do not expose raw C++ pointers to Dart.
* Do not call platform channels from the audio thread.

---

## 17. Definition of Done

A ticket is done only when:

* All acceptance criteria and the **demo script** pass.
* The feature is visible and/or audible if it is user-facing — including **dialogs, feedback, and error states** named in the ticket.
* Required tests are added or updated (C++ round-trip uses real serialized output where applicable).
* Relevant docs are updated.
* Realtime implications are considered.
* No fake UI-only implementation is presented as real.
* No “phase 2” follow-up is required for the same user story (e.g. adding save dialog after “save works internally”).
* Framework primitives used per §2.6 (JUCE JSON, system document pickers).
* The app still builds.
* The Android on-device demo script succeeds.

For audio tickets, done also requires:

* real JUCE audio path
* no known audio-thread safety violation
* no unbounded allocations in audio callback
* deterministic tests where possible

For persistence tickets, done also requires:

* save → load round-trip on device restores tracks, clips, devices, and parameters
* user cancel and failure paths verified
* no silent empty state on successful load

---

## 18. Cursor Behavior Rules

When working as the coding agent:

1. First inspect existing files.
2. Do not assume architecture that is not documented.
3. If docs are missing, create or update docs before implementation.
4. Work from tickets.
5. Keep changes small.
6. Avoid large rewrites.
7. Never hide unfinished work behind polished UI.
8. Never claim audio works unless there is a real JUCE path.
9. Prefer clean separation of concerns.
10. Reuse JUCE and OS APIs — do not reinvent JSON, file pickers, or zip I/O (§2.6).
11. Implement the **full** user story in one slice — UX, bridge, engine, tests, demo script (§2.7).
12. Ship **investor-quality** increments: bold complete solutions, no overengineering, mobile UX verified on device (§2.8).
13. Plan ahead enough to avoid dead ends, but do not overengineer before the first sound.
14. Update ADRs when architecture changes.
15. Keep Flutter and JUCE decoupled.
16. Keep engine reusable outside Flutter.
17. Keep MVP Android-first.
18. Avoid iOS-specific work unless explicitly requested.
19. Avoid server/cloud/account features.
20. Avoid external plugin hosting.
21. Keep project files versioned and diffable.
22. Always preserve realtime safety.

---

## 19. First Task for Cursor

Start by creating the repository structure, documentation skeleton, ADRs, milestone documents, and local tickets.

Do not begin with a large implementation.

Create:

```text
README.md
AGENT.md
docs/architecture/overview.md
docs/architecture/realtime_audio_rules.md
docs/architecture/project_model.md
docs/architecture/audio_graph.md
docs/architecture/device_model.md
docs/bridge/flutter_native_bridge.md
docs/guidelines/cpp_guidelines.md
docs/guidelines/flutter_guidelines.md
docs/guidelines/mobile_ui_guidelines.md
docs/guidelines/testing_guidelines.md
docs/guidelines/git_workflow.md
docs/guidelines/versioning.md
docs/testing/performance_budgets.md
docs/adr/ADR-0001-flutter-juce-architecture.md
docs/adr/ADR-0002-android-first-mvp.md
docs/adr/ADR-0003-graph-based-engine.md
docs/adr/ADR-0004-no-external-plugin-formats.md
docs/adr/ADR-0005-diffable-project-format.md
docs/adr/ADR-0006-os-bridge-project-files.md
tickets/milestone-00/
tickets/milestone-01/
tickets/milestone-02/
```

Then create initial tickets for:

* project bootstrap
* Flutter Android shell
* JUCE engine skeleton
* Flutter/native bridge spike
* realtime audio rules
* first playable JUCE oscillator from Flutter
* visible timeline/device-strip placeholder
* first project/track/device model

Only after that, implement Milestone 01: Flutter Play button triggering real JUCE-generated audio on Android.

## Dev Environment / Dev Container

Before implementing app features, set up a reproducible development environment.

The project must support development through a **Dev Container** so that Android/Flutter/JUCE/C++ tooling is consistent and easy to bootstrap.

The dev environment is part of Milestone 00 and must be created before meaningful implementation work starts.

### Goals

The dev container should provide:

* Flutter SDK
* Dart SDK
* Android SDK command-line tools
* Android build tools
* Gradle/JDK required for Android builds
* CMake
* Ninja
* Clang/GCC toolchain
* JUCE build prerequisites
* Git
* Python or scripting tools if needed
* basic formatting/linting tools
* reproducible local build commands

The first target is Android. iOS tooling is explicitly out of scope for the dev container because iOS builds require macOS/Xcode.

### Required files

Create:

```text
.devcontainer/
  devcontainer.json
  Dockerfile
  postCreateCommand.sh
  README.md
```

Optional but useful:

```text
tools/
  doctor.sh
  build_android.sh
  test_all.sh
  format_all.sh
```

### Dev container requirements

The container must:

* install or provide Flutter
* install Android SDK command-line tools
* accept Android SDK licenses during setup where legally/technically possible
* expose clear environment variables:

  * `ANDROID_HOME`
  * `ANDROID_SDK_ROOT`
  * `FLUTTER_HOME`
  * `PATH`
* support `flutter doctor`
* support `flutter build apk` for the Android app once the Flutter skeleton exists
* support CMake/Ninja builds for the JUCE/C++ engine
* document any host requirements, especially Android emulator/device access

### Android device/emulator note

Do not assume Android emulator acceleration works inside the container.

Document at least two development modes:

1. **Build in container, run on host/device**

   * use a physical Android device connected to the host
   * or use a host-managed emulator
   * container builds APK
   * install/run via host tools or forwarded ADB where configured

2. **Container with ADB access**

   * document how ADB must be exposed/mounted if supported
   * do not make this mandatory for MVP

The dev container is allowed to focus on reproducible builds first. Running the emulator inside the container is not required.

### JUCE dependency strategy

Do not silently vendor a random JUCE copy.

Document the chosen JUCE setup in:

```text
docs/architecture/juce_dependency.md
```

Acceptable options:

* pin JUCE as a Git submodule
* pin JUCE through CMake FetchContent
* document a manually installed JUCE path for early bootstrap

Prefer a pinned, reproducible option.

The selected JUCE version must be documented.

### Milestone 00 addition

Milestone 00 must now include:

* `.devcontainer/devcontainer.json`
* `.devcontainer/Dockerfile`
* `.devcontainer/postCreateCommand.sh`
* `.devcontainer/README.md`
* `tools/doctor.sh`
* initial Flutter/JUCE/Android toolchain verification
* documentation for host requirements
* documentation for Android device/emulator workflow
* documented JUCE dependency strategy

### Dev environment acceptance criteria

Milestone 00 is not complete until:

* dev container builds successfully
* `flutter doctor` runs inside the container
* Android SDK is detected
* CMake and Ninja are available
* JDK/Gradle tooling is available
* the repository has a documented “doctor” command
* the Flutter Android skeleton can be built from inside the container
* the native/JUCE skeleton can be configured or built from inside the container
* limitations around emulator/device access are documented honestly

### First Task update

The first task for Cursor is now:

1. Create the repository structure.
2. Create the dev container.
3. Add `tools/doctor.sh`.
4. Document setup in `.devcontainer/README.md` and root `README.md`.
5. Add architecture docs and ADR skeletons.
6. Add milestone/ticket structure.
7. Verify the Flutter/Android/JUCE build path.
8. Only then start the first playable Flutter → JUCE audio slice.
