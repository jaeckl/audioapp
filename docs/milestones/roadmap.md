# Product Roadmap — User Stories

Vertical slices only. Each story follows [AGENT.md](../../AGENT.md) §14 (UX flow, platform UX, demo script, investor bar §2.8).

## Phases

| Phase | Milestones | Theme |
|-------|------------|-------|
| **0 — Foundation** | M00 | Repo, docs, toolchain, shell |
| **1 — Audio proof** | M01 | Flutter → native engine → speaker |
| **2 — Core DAW loop** | M02–M04 | Tracks, devices, MIDI, editing |
| **3 — Persistence** | M05 | Save/load `.audioapp.zip` |
| **4 — Samples** | M06–M07 | Library, sampler, trim editor |
| **5 — Mix & export** | M08–M09 | Effects, automation, WAV export |

---

## Milestone 00 — Foundation

| ID | Summary | Status |
|----|---------|--------|
| [US-00-01](../../tickets/milestone-00/US-00-01-developer-onboarding.md) | Developer onboarding & build | Done |
| [US-00-02](../../tickets/milestone-00/US-00-02-daw-shell-placeholder.md) | DAW shell placeholder | Done |
| [US-00-03](../../tickets/milestone-00/US-00-03-edge-to-edge-shell-layout.md) | Edge-to-edge layout | Done |

---

## Milestone 01 — First real sound

| ID | Summary | Status |
|----|---------|--------|
| [US-01-01](../../tickets/milestone-01/US-01-01-play-hears-juce-audio.md) | Play/Stop audible on device | Done |

---

## Milestone 02 — Track & device strip

| ID | Summary | Status |
|----|---------|--------|
| [US-02-01](../../tickets/milestone-02/US-02-01-add-track.md) | Add track | Done |
| [US-02-02](../../tickets/milestone-02/US-02-02-select-track.md) | Select track → device strip | Done |
| [US-02-03](../../tickets/milestone-02/US-02-03-oscillator-device-strip.md) | Oscillator frequency audible | Done |

---

## Milestone 03 — MIDI clip playback

| ID | Summary | Status |
|----|---------|--------|
| [US-03-01](../../tickets/milestone-03/US-03-01-create-midi-clip-on-timeline.md) | Create MIDI clip on timeline | Done |
| [US-03-02](../../tickets/milestone-03/US-03-02-transport-playhead.md) | Transport playhead | Done |
| [US-03-03](../../tickets/milestone-03/US-03-03-midi-clip-playback.md) | MIDI clip → audio playback | Done |

---

## Milestone 04 — Mobile MIDI editing

| ID | Summary | Status |
|----|---------|--------|
| [US-04-01](../../tickets/milestone-04/US-04-01-open-piano-roll.md) | Open piano roll from clip | Done |
| [US-04-02](../../tickets/milestone-04/US-04-02-add-delete-notes.md) | Add/delete notes | Done |
| [US-04-03](../../tickets/milestone-04/US-04-03-move-resize-notes-grid-snap.md) | Move/resize + grid snap | Done |

---

## Milestone 05 — Save & load

| ID | Summary | Status |
|----|---------|--------|
| [US-05-01](../../tickets/milestone-05/US-05-01-save-project.md) | Save via system dialog → zip | Done |
| [US-05-02](../../tickets/milestone-05/US-05-02-load-project.md) | Load via system picker | Done |

**PO demo:** Save → force-stop → Load → arrangement restored.

---

## Milestone 06 — Sample library & sampler

| ID | Summary | Status |
|----|---------|--------|
| [US-06-01](../../tickets/milestone-06/US-06-01-bundled-sample-library.md) | Bundled starter pack + library UI | Todo |
| [US-06-02](../../tickets/milestone-06/US-06-02-import-sample-system-picker.md) | Import via system file picker | Todo |
| [US-06-03](../../tickets/milestone-06/US-06-03-sampler-device-on-strip.md) | Sampler on device strip | Todo |
| [US-06-04](../../tickets/milestone-06/US-06-04-midi-triggers-sample.md) | MIDI triggers sample loop | Todo |

**PO demo:** Sampler + 4-on-floor → Save → Load → same loop.

---

## Milestone 07 — Sampler fullscreen editor

| ID | Summary | Status |
|----|---------|--------|
| [US-07-01](../../tickets/milestone-07/US-07-01-open-fullscreen-sampler.md) | Open fullscreen sampler | Todo |
| [US-07-02](../../tickets/milestone-07/US-07-02-waveform-trim-editor.md) | Waveform + trim handles | Todo |

---

## Milestone 08 — Effects & automation

| ID | Summary | Status |
|----|---------|--------|
| [US-08-01](../../tickets/milestone-08/US-08-01-gain-device.md) | Gain effect | Todo |
| [US-08-02](../../tickets/milestone-08/US-08-02-pan-device.md) | Pan effect | Todo |
| [US-08-03](../../tickets/milestone-08/US-08-03-filter-device.md) | Filter effect | Todo |
| [US-08-04](../../tickets/milestone-08/US-08-04-parameter-automation.md) | Parameter automation | Todo |

---

## Milestone 09 — Offline render

| ID | Summary | Status |
|----|---------|--------|
| [US-09-01](../../tickets/milestone-09/US-09-01-offline-render-engine.md) | Offline render engine | Todo |
| [US-09-02](../../tickets/milestone-09/US-09-02-export-wav-system-dialog.md) | Export WAV via save dialog | Todo |

---

## Dependency graph

```text
M00 ──► M01 ──► M02 ──► M03 ──► M04
                      └──► M05 ──► M06 ──► M07
                               └──► M08 ──► M09
```

[tickets/README.md](../../tickets/README.md) · [Companion stories](../../tickets/COMPANION_STORIES.md) · Story template: AGENT.md §14
