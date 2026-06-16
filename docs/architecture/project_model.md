# Project Model

## Authority

The C++ project engine is the single source of truth. Flutter receives projections for rendering.

## Core entities

```text
Project
├── metadata (name, format version, app version)
├── transport (bpm, playing, playhead beats)
├── tracks[]
│   ├── id, name, color
│   ├── device_chain[]
│   └── clips[]
├── sample_library_refs[]
└── routing (future buses)
```

## Stable IDs

All persistent entities use stable string or UUID IDs:

- `track_id`, `clip_id`, `device_id`, `parameter_id`, `sample_id`, `automation_target_id`

IDs survive save/load and must not be regenerated on load.

## Commands (mutation)

Mutations arrive as explicit commands (see bridge doc). Examples:

- `createProject`, `addTrack`, `createMidiClip`, `addDeviceToTrack`
- `setDeviceParameter`, `play`, `stop`, `setBpm`
- `saveProject`, `loadProject`

Commands should be representable as undoable operations (architecture from day one; full undo not required in early milestones).

## Serialization

On-disk format: **`.audioapp.zip`** archive ([ADR-0005](../adr/ADR-0005-diffable-project-format.md)):

```text
project.audioapp.zip
├── project.json          # human-readable, diffable, versioned
├── assets/samples/       # binary samples (M06+)
└── metadata/             # sidecar files
```

- `project.json` is the structural source of truth inside the zip.
- Large binary data lives under `assets/`, referenced from JSON.
- `project_format_version` required in `project.json`.

### Who writes archives (hybrid — [ADR-0006](../adr/ADR-0006-os-bridge-project-files.md))

| Platform | Archive I/O | Serialize / deserialize |
|----------|-------------|-------------------------|
| **Android** | Kotlin `ProjectArchiveStore` + SAF save/open dialogs | C++ JNI (`juce::JSON` on control thread) |
| **Desktop / tests** | C++ `ProjectArchive.cpp` | C++ `ProjectJson.cpp` (`juce::JSON`) |
| **Flutter** | None (Save/Load UI → MethodChannel) | None |

- **Save / Load** open system save/open dialogs for `project.audioapp.zip`.
- Cancel → no error; project state unchanged on load cancel.

## MVP constraints

- Fixed BPM (no tempo map)
- Arrangement-first (session/clip launcher later)
- MIDI clips before audio clips in priority

## Flutter projection

Flutter caches a read-only snapshot for UI:

- track list, clip regions, device chain summary, parameter values
- transport: `playheadBeats`, `playing`
- Updated via engine events, not by duplicating mutation logic in Dart

## Snapshot JSON (bridge projection)

Live UI snapshot returned by engine commands (`getProjectSnapshot`, mutations):

```json
{
  "bpm": 120,
  "playheadBeats": 0.0,
  "playing": false,
  "selectedTrackId": "track-1",
  "tracks": [
    {
      "id": "track-1",
      "name": "Track 1",
      "devices": [
        {
          "id": "dev-1",
          "type": "simple_oscillator",
          "parameters": { "frequency": 440.0 }
        }
      ],
      "midiClips": [
        {
          "id": "clip-1",
          "startBeat": 0.0,
          "lengthBeats": 4.0,
          "notes": [
            {
              "pitch": 60,
              "startBeat": 0.0,
              "durationBeats": 1.0,
              "velocity": 100.0
            }
          ]
        }
      ]
    }
  ]
}
```

## `project.json` inside the archive (M05)

Pretty-printed, diffable, `project_format_version: 1`. Transport state (`playheadBeats`, `playing`) is not persisted in v1.

```json
{
  "project_format_version": 1,
  "name": "Untitled",
  "bpm": 120,
  "selectedTrackId": "track-1",
  "tracks": []
}
```

(Unzip any `.audioapp.zip` to inspect or diff `project.json` in git.)
