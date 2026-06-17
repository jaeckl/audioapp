# Product Roadmap — User Stories (expanded)

**~20 vertical slices per milestone** (200 total). Each story is one shippable slice per [AGENT.md](../../AGENT.md) §14.

**Manifest (machine-readable):** [tickets/story_manifest.yaml](../../tickets/story_manifest.yaml)

**Legend:** ✅ Done · 🔄 In progress · ⬜ Todo · ⏸ Deferred

---

## Phases

| Phase | Milestones | Theme | Stories |
|-------|------------|-------|---------|
| **0 — Foundation** | M00 | Repo, toolchain, shell, bridge | 20 |
| **1 — Audio proof** | M01 | Flutter → JUCE → speaker | 20 |
| **2 — Core DAW loop** | M02–M04 | Tracks, devices, MIDI, editing | 60 |
| **3 — Persistence** | M05 | Save/load `.audioapp.zip` | 20 |
| **4 — Samples** | M06–M07 | Library, clips, sampler UX, shell | 40 |
| **5 — Mix & export** | M08–M09 | Real DSP, automation, WAV export | 40 |
| **6 — Flagship instrument** | M11 | Subtractive synth (8-voice, LP12) | 10 |

---

## Milestone 00 — Foundation

| ID | Summary | Status |
|----|---------|--------|
| US-00-01 | Developer onboarding & reproducible build | ✅ |
| US-00-02 | DAW shell three-band layout placeholder | ✅ |
| US-00-03 | Edge-to-edge layout & safe-area insets | ✅ |
| US-00-04 | Flutter ↔ native MethodChannel bridge scaffold | ✅ |
| US-00-05 | JUCE engine static lib & CMake fetch | ✅ |
| US-00-06 | Engine smoke test executable | ✅ |
| US-00-07 | Project documentation skeleton (AGENT, ADRs) | ✅ |
| US-00-08 | Dark flat theme tokens & Material baseline | ✅ |
| US-00-09 | Transport bar chrome (BPM, playhead, version) | ✅ |
| US-00-10 | Android adb doctor & Windows setup guide | ✅ |
| US-00-11 | Bridge ping/pong health check in shell | ✅ |
| US-00-12 | Native bridge error envelope (ok + message) | ✅ |
| US-00-13 | Repo folder layout (flutter / engine / bridge) | ✅ |
| US-00-14 | Flutter widget smoke test bootstraps shell | ✅ |
| US-00-15 | Flutter deploy script & device auto-install | 🔄 |
| US-00-16 | CI — engine tests on push | ⬜ |
| US-00-17 | CI — Flutter analyze & widget tests | ⬜ |
| US-00-18 | Crash-safe engine init & boot failure UX | ⬜ |
| US-00-19 | Structured logging channel (control thread) | ⬜ |
| US-00-20 | Release vs debug build flavors documented | ⬜ |

**PO demo:** Clone repo → build engine + Flutter → deploy to phone → shell visible → bridge pong.

---

## Milestone 01 — First real sound

| ID | Summary | Status |
|----|---------|--------|
| US-01-01 | Play/Stop audible test tone on device | ✅ |
| US-01-02 | AAudio output path on Android | ✅ |
| US-01-03 | EngineHost lifecycle (start/stop audio) | ✅ |
| US-01-04 | TestOscillator RT-safe sine generator | ✅ |
| US-01-05 | Bridge play/stop commands | ✅ |
| US-01-06 | Transport UI toggles play state | ✅ |
| US-01-07 | Master gain parameter & soft clip | ✅ |
| US-01-08 | Silence when transport stopped | ✅ |
| US-01-09 | C++ oscillator output golden test | ✅ |
| US-01-10 | Android audio focus (duck/pause on call) | ⬜ |
| US-01-11 | Buffer size / latency note in settings | ⬜ |
| US-01-12 | Underrun counter (debug overlay) | ⬜ |
| US-01-13 | Background → foreground audio resume | ⬜ |
| US-01-14 | CPU wake lock only while playing | ⬜ |
| US-01-15 | Output device change notification | ⬜ |
| US-01-16 | Sample rate negotiation (48 kHz default) | ⬜ |
| US-01-17 | RT safety checklist for contributors | ⬜ |
| US-01-18 | Engine thread priority boost on Android | ⬜ |
| US-01-19 | First-run audio permission UX (if required) | ⬜ |
| US-01-20 | M01 PO demo script (signed-off checklist) | ⬜ |

**PO demo:** Tap Play → hear tone → Stop → silence.

---

## Milestone 02 — Tracks & device strip

| ID | Summary | Status |
|----|---------|--------|
| US-02-01 | Add track (engine + bridge + UI) | ✅ |
| US-02-02 | Select track → show device strip | ✅ |
| US-02-03 | Oscillator device strip & frequency parameter | ✅ |
| US-02-04 | Device & track IDs in project model | ✅ |
| US-02-05 | Auto-insert track_gain on new track | ✅ |
| US-02-06 | Track row in arrangement view | ✅ |
| US-02-07 | Selected track highlight | ✅ |
| US-02-08 | Empty device strip hint | ✅ |
| US-02-09 | C++ project_engine_test | ✅ |
| US-02-10 | Default instrument sampler on new track | ✅ |
| US-02-11 | addDeviceToTrack bridge API | ✅ |
| US-02-12 | Rename track | ⬜ |
| US-02-13 | Delete track with confirm | ⬜ |
| US-02-14 | Reorder tracks (drag) | ⬜ |
| US-02-15 | Max track count guard + message | ⬜ |
| US-02-16 | Duplicate track | ⬜ |
| US-02-17 | Track color/icon picker | ⬜ |
| US-02-18 | Device strip height per device type | ⬜ |
| US-02-19 | Instrument vs FX device categories | ⬜ |
| US-02-20 | M02 PO demo — two tracks, two timbres | ⬜ |

---

## Milestone 03 — MIDI clip playback

| ID | Summary | Status |
|----|---------|--------|
| US-03-01 | Create MIDI clip on timeline | ✅ |
| US-03-02 | Transport playhead position & advance | ✅ |
| US-03-03 | MIDI clip note → audible pitch | ✅ |
| US-03-04 | Clip start beat & length in model | ✅ |
| US-03-05 | Seed note in new MIDI clip | ✅ |
| US-03-06 | Note duration & velocity in playback | ✅ |
| US-03-07 | Clip looping within lengthBeats | ✅ |
| US-03-08 | BPM affects playhead advance | ✅ |
| US-03-09 | C++ midi_clip_playback_test | ✅ |
| US-03-10 | MIDI clip block on arrangement | ✅ |
| US-03-11 | Set project BPM from transport | ⬜ |
| US-03-12 | Tap tempo | ⬜ |
| US-03-13 | Loop region / cycle playback | ⬜ |
| US-03-14 | Metronome click | ⬜ |
| US-03-15 | Count-in before record | ⬜ |
| US-03-16 | Multiple MIDI clips per track | ⬜ |
| US-03-17 | Clip mute flag | ⬜ |
| US-03-18 | Overlapping note priority rules | ⬜ |
| US-03-19 | Stop vs pause semantics | ⬜ |
| US-03-20 | M03 PO demo — two-bar loop | ⬜ |

---

## Milestone 04 — Mobile MIDI editing

| ID | Summary | Status |
|----|---------|--------|
| US-04-01 | Open piano roll from MIDI clip | ✅ |
| US-04-02 | Add & delete notes | ✅ |
| US-04-03 | Move & resize notes + grid snap | ✅ |
| US-04-04 | setMidiClipNotes bridge round-trip | ✅ |
| US-04-05 | Piano roll grid & pitch rows | ✅ |
| US-04-06 | Close piano roll → arrangement | ✅ |
| US-04-07 | Note velocity edit | ⬜ |
| US-04-08 | Multi-select notes | ⬜ |
| US-04-09 | Duplicate selected notes | ⬜ |
| US-04-10 | Quantize selection | ⬜ |
| US-04-11 | Piano roll horizontal scroll & clip bounds | ✅ |
| US-04-12 | Piano roll pinch zoom | ⬜ |
| US-04-13 | Undo/redo note edits | ⬜ |
| US-04-14 | Copy/paste notes across clips | ⬜ |
| US-04-15 | Clip length resize in arrangement | ⬜ |
| US-04-16 | Duplicate MIDI clip | ⬜ |
| US-04-17 | Delete MIDI clip with confirm | ⬜ |
| US-04-18 | MIDI clip rename / color | ⬜ |
| US-04-19 | Piano roll landscape lock (optional) | ⬜ |
| US-04-20 | M04 PO demo — sketch melody on device | ⬜ |

---

## Milestone 05 — Save & load

| ID | Summary | Status |
|----|---------|--------|
| US-05-01 | Save via SAF CreateDocument (.audioapp.zip) | ✅ |
| US-05-02 | Load via SAF OpenDocument | ✅ |
| US-05-03 | project.json schema v1 (juce::JSON) | ✅ |
| US-05-04 | Zip archive packs JSON + sample refs | ✅ |
| US-05-05 | Settings save/load entry points | ✅ |
| US-05-06 | C++ project_archive round-trip tests | ✅ |
| US-05-07 | Success & error feedback in shell | ✅ |
| US-05-08 | Cancel save/load unchanged state | ⬜ |
| US-05-09 | Invalid file format message | ⬜ |
| US-05-10 | New project / discard changes confirm | ⬜ |
| US-05-11 | Autosave draft to sandbox | ⬜ |
| US-05-12 | Project dirty flag & unsaved indicator | ⬜ |
| US-05-13 | Embed imported samples in zip | ⬜ |
| US-05-14 | Missing sample on load — relink UI | ⬜ |
| US-05-15 | Format version migrate hook (stub) | ⬜ |
| US-05-16 | Default filename from project name | ⬜ |
| US-05-17 | Restore selected track & playhead on load | ⬜ |
| US-05-18 | Large project save progress | ⬜ |
| US-05-19 | C++ malformed zip rejection tests | ⬜ |
| US-05-20 | M05 PO demo — force-stop → reload | ⬜ |

---

## Milestone 06 — Sample library & audio clips

| ID | Summary | Status |
|----|---------|--------|
| US-06-01 | Bundled starter pack + library tab | ✅ |
| US-06-02 | Import sample via system picker | ✅ |
| US-06-03 | Insert sample clip on track | ✅ |
| US-06-04 | Waveform peaks in arrangement | ✅ |
| US-06-05 | Sample clip audible at playhead | ✅ |
| US-06-06 | Compact icon track headers | ✅ |
| US-06-07 | Minimum readable clip width | ✅ |
| US-06-08 | Pinch horizontal zoom | ✅ |
| US-06-09 | Horizontal scroll timeline | ✅ |
| US-06-10 | Master track row (bottom) | ✅ |
| US-06-11 | Equal-sum master bus | ✅ |
| US-06-12 | Preview sample in library | ✅ |
| US-06-13 | WAV decode + peak cache | ✅ |
| US-06-14 | MIDI-triggered sampler playback | 🔄 |
| US-06-15 | Sample clip drag move / cross-track | ⬜ |
| US-06-16 | Sample clip resize (length) | ⬜ |
| US-06-17 | Duplicate sample clip | ⬜ |
| US-06-18 | Delete sample clip with confirm | ⬜ |
| US-06-19 | Library search/filter by name | ⬜ |
| US-06-20 | M06 PO demo — kick/snare → play → save | ⬜ |

---

## Milestone 07 — Shell, mixer & sampler UX

| ID | Summary | Status |
|----|---------|--------|
| US-07-01 | Open fullscreen sampler (landscape) | ✅ |
| US-07-02 | Waveform trim handles + preview | ⬜ |
| US-07-03 | Portrait bottom navigation | ✅ |
| US-07-04 | Mixer tab + track_gain | ✅ |
| US-07-05 | Arrangement chrome cleanup | ✅ |
| US-07-06 | Landscape nav physical edge | ✅ |
| US-07-07 | Sampler device strip (Bitwig layout) | ✅ |
| US-07-08 | ADSR + filter panel UI | ✅ |
| US-07-09 | Device strip uniform scale | ✅ |
| US-07-10 | Shared panel strip + fullscreen | ✅ |
| US-07-11 | Assign sampleId (string parameter) | ✅ |
| US-07-12 | Fullscreen live parameter state | ✅ |
| US-07-13 | Load sample from fullscreen picker | ⬜ |
| US-07-14 | Root key & tune (basic) | ⬜ |
| US-07-15 | Sampler gain device parameter only | ⬜ |
| US-07-16 | Playhead scrub from transport | ⬜ |
| US-07-17 | Settings project metadata (name, BPM) | ⬜ |
| US-07-18 | In-app changelog / version sheet | ⬜ |
| US-07-19 | Haptic feedback on key actions | ⬜ |
| US-07-20 | M07 PO demo — fullscreen + mixer | ⬜ |

---

## Milestone 08 — Device chain DSP & mix

| ID | Summary | Status |
|----|---------|--------|
| US-08-01 | track_gain in ordered device chain | ✅ |
| US-08-02 | Device chain executor | ✅ |
| US-08-03 | Sampler default (no hidden oscillator) | ✅ |
| US-08-04 | Sampler ADSR envelope DSP | ⬜ |
| US-08-05 | Sampler multimode filter DSP | ⬜ |
| US-08-06 | Pan device in chain | ⬜ |
| US-08-07 | Dedicated filter effect device | ⬜ |
| US-08-08 | Per-device bypass toggle | ⬜ |
| US-08-09 | Add/remove device UI | ⬜ |
| US-08-10 | Device chain drag-reorder | ⬜ |
| US-08-11 | Solo track | ⬜ |
| US-08-12 | Mute track | ⬜ |
| US-08-13 | Peak meter on mixer channel | ⬜ |
| US-08-14 | Master bus limiter polish | ⬜ |
| US-08-15 | Sampler voice stealing / max voices | ⬜ |
| US-08-16 | RT-safe parameter smoothing | ⬜ |
| US-08-17 | C++ golden tests per effect | ⬜ |
| US-08-18 | Automation lane data model | ⬜ |
| US-08-19 | Automation playback on transport | ⬜ |
| US-08-20 | M08 PO demo — filter sweep + automation | ⬜ |

---

## Milestone 09 — Offline render & export

| ID | Summary | Status |
|----|---------|--------|
| US-09-01 | Offline render engine | ⬜ |
| US-09-02 | Export WAV via save dialog | ⬜ |
| US-09-03 | Render progress % | ⬜ |
| US-09-04 | Cancel render | ⬜ |
| US-09-05 | Export length = arrangement length | ⬜ |
| US-09-06 | Export all tracks summed | ⬜ |
| US-09-07 | Export respects sampler trim | ⬜ |
| US-09-08 | 44.1 kHz stereo 16-bit WAV | ⬜ |
| US-09-09 | C++ golden offline render test | ⬜ |
| US-09-10 | Export button in settings | ⬜ |
| US-09-11 | Default export filename | ⬜ |
| US-09-12 | Export error paths (disk, permission) | ⬜ |
| US-09-13 | Optional share sheet after export | ⬜ |
| US-09-14 | Export normalize peak option | ⬜ |
| US-09-15 | Export tail for release/reverb | ⬜ |
| US-09-16 | Bridge renderProject async command | ⬜ |
| US-09-17 | Faster-than-RT benchmark test | ⬜ |
| US-09-18 | Export loop range only | ⬜ |
| US-09-19 | Stem export (per track) — stretch | ⬜ |
| US-09-20 | M09 PO demo — external player playback | ⬜ |

**PO demo:** Export arrangement → open in external player → confirm levels.

---

## Milestone 11 — Subtractive synth instrument

| ID | Summary | Status |
|----|---------|--------|
| US-11-01 | Engine MVP — 8-voice poly, saw, amp ADSR, LP12 + filter env | ⬜ |
| US-11-02 | Device picker, minimal strip, save/load, coexist with oscillator | ⬜ |
| US-11-03 | Dual oscillators + unison | ⬜ |
| US-11-04 | Noise + osc mix modes (mix/neg/am/sign/max) | ⬜ |
| US-11-05 | Osc tab + waveform preview painters | ⬜ |
| US-11-06 | Mix, Filter, Amp strip tabs | ⬜ |
| US-11-07 | Fullscreen editor + test note | ⬜ |
| US-11-08 | Factory presets + content library | ⬜ |
| US-11-09 | Glide + velocity (no LFO) | ⬜ |
| US-11-20 | M11 PO demo — subtractive synth end-to-end | ⬜ |

**Locked:** poly **8** voices · **LP12 only** · **`subtractive_synth` coexists** with `simple_oscillator` · **no LFO** in M11.

**PO demo:** Add synth → dual osc pad → filter sweep → preset from library → save/reload → play alongside oscillator on track 2.

---

## Dependency graph

```text
M00 ──► M01 ──► M02 ──► M03 ──► M04
                      └──► M05 ──► M06 ──► M07
                               └──► M08 ──► M09
                      └──► M11 (after M08-02, M10-02 live notes)
```

**Critical path to investor demo:** M06-14 (sampler MIDI) → M08-04/05 (real ADSR/filter) → M07-02 (trim) → M09-01/02 (export).

---

## Ticket files

Not every story has a full `US-XX-YY-*.md` ticket yet. Priority:

1. Stories marked ⬜ in **current sprint** get full AGENT.md §14 tickets + companions.
2. Run `python tools/gen_companion_tickets.py` after adding to manifest.
3. Retroactive ✅ stories may stay roadmap-only unless auditing compliance.

[tickets/README.md](../../tickets/README.md) · [story_manifest.yaml](../../tickets/story_manifest.yaml)
