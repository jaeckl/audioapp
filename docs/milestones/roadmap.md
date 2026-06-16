# Product Roadmap — User Stories

Vertical slices only. Each user story must be visible, testable, and (when audio-related) use a real JUCE path.

## Phases

| Phase | Milestones | Theme |
|-------|------------|-------|
| **0 — Foundation** | M00 | Repo, docs, toolchain, placeholder shell |
| **1 — Audio proof** | M01 | Flutter → bridge → JUCE → speaker |
| **2 — Core DAW loop** | M02–M04 | Tracks, devices, MIDI clips, editing |
| **3 — Persistence** | M05 | Save/load diffable projects |
| **4 — Samples** | M06–M07 | Library, sampler, trim editor |
| **5 — Mix & export** | M08–M09 | Effects, automation, offline render |

---

## Milestone 00 — Foundation

| ID | User story | Status |
|----|------------|--------|
| [US-00-01](../../tickets/milestone-00/US-00-01-developer-onboarding.md) | As a **developer**, I can set up the repo on Windows/Android and build the app and engine skeleton. | Done |
| [US-00-02](../../tickets/milestone-00/US-00-02-daw-shell-placeholder.md) | As a **user**, I open the app and see a clear DAW layout (timeline, transport, device strip placeholders). | Done |

**User-visible outcome:** App installs and shows where the DAW will live. No fake audio.

---

## Milestone 01 — First real sound

| ID | User story | Status |
|----|------------|--------|
| [US-01-01](../../tickets/milestone-01/US-01-01-play-hears-juce-audio.md) | As a **user**, I press Play and hear real sound from the JUCE engine on my Android device. | Todo |

**User-visible outcome:** Audible test tone; Stop silences it.

---

## Milestone 02 — Track & device strip

| ID | User story | Status |
|----|------------|--------|
| [US-02-01](../../tickets/milestone-02/US-02-01-add-and-select-track.md) | As a **user**, I can add a track and select it in the arrangement. | Todo |
| [US-02-02](../../tickets/milestone-02/US-02-02-device-strip-oscillator.md) | As a **user**, I see the device strip for the selected track and change an oscillator parameter with audible effect. | Todo |

**User-visible outcome:** First real DAW interaction — track + instrument strip controls sound.

---

## Milestone 03 — MIDI clip playback

| ID | User story | Status |
|----|------------|--------|
| [US-03-01](../../tickets/milestone-03/US-03-01-create-midi-clip-on-timeline.md) | As a **user**, I can create a MIDI clip on a track and see it on the timeline. | Todo |
| [US-03-02](../../tickets/milestone-03/US-03-02-play-midi-through-device.md) | As a **user**, I press Play and hear the clip’s notes through the track’s oscillator at fixed BPM, with looping. | Todo |

**User-visible outcome:** Arrangement plays a MIDI pattern through the device chain.

---

## Milestone 04 — Mobile MIDI editing

| ID | User story | Status |
|----|------------|--------|
| [US-04-01](../../tickets/milestone-04/US-04-01-open-piano-roll.md) | As a **user**, I can open a mobile-friendly piano roll from a clip on the timeline. | Todo |
| [US-04-02](../../tickets/milestone-04/US-04-02-edit-notes-in-piano-roll.md) | As a **user**, I can add, move, resize, and delete notes with grid snapping and hear changes on playback. | Todo |

**User-visible outcome:** Write a simple melody or rhythm on the phone.

---

## Milestone 05 — Save & load

| ID | User story | Status |
|----|------------|--------|
| [US-05-01](../../tickets/milestone-05/US-05-01-save-project.md) | As a **user**, I can save my project to a versioned folder with diffable `project.json`. | Todo |
| [US-05-02](../../tickets/milestone-05/US-05-02-load-project.md) | As a **user**, I can load a saved project and continue with tracks, clips, devices, and parameters restored. | Todo |

**User-visible outcome:** Projects survive app restart.

---

## Milestone 06 — Sample library & sampler

| ID | User story | Status |
|----|------------|--------|
| [US-06-01](../../tickets/milestone-06/US-06-01-sample-library-import.md) | As a **user**, I can browse a sample library and import/reference a local audio file. | Todo |
| [US-06-02](../../tickets/milestone-06/US-06-02-sampler-midi-trigger.md) | As a **user**, I can load a sample into a sampler device and trigger it from a MIDI clip. | Todo |

**User-visible outcome:** Simple sample-based loop.

---

## Milestone 07 — Sampler fullscreen editor

| ID | User story | Status |
|----|------------|--------|
| [US-07-01](../../tickets/milestone-07/US-07-01-sampler-fullscreen-trim.md) | As a **user**, I can open the sampler fullscreen, set trim start/end, and hear playback respect trim without changing the source file. | Todo |

**User-visible outcome:** Shape samples non-destructively.

---

## Milestone 08 — Effects & automation

| ID | User story | Status |
|----|------------|--------|
| [US-08-01](../../tickets/milestone-08/US-08-01-effect-device-chain.md) | As a **user**, I can add gain, pan, and filter devices after an instrument and hear the mix change. | Todo |
| [US-08-02](../../tickets/milestone-08/US-08-02-parameter-automation.md) | As a **user**, I can target a device parameter with simple automation data that affects playback. | Todo |

**User-visible outcome:** Shape sound through the device strip.

---

## Milestone 09 — Offline render

| ID | User story | Status |
|----|------------|--------|
| [US-09-01](../../tickets/milestone-09/US-09-01-export-project-wav.md) | As a **user**, I can export/render the current project to a local WAV file faster than realtime. | Todo |

**User-visible outcome:** Share a rendered loop or track.

---

## Dependency graph

```text
M00 ──► M01 ──► M02 ──► M03 ──► M04
                      └──► M05 ──► M06 ──► M07
                               └──► M08 ──► M09
```

## Ticket index

All implementation tickets live under `tickets/milestone-XX/`. See [tickets/README.md](../../tickets/README.md).
