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

Folder-based project:

```text
MyProject/
  project.json
  assets/samples/
  metadata/
  renders/
```

- `project.json` — human-readable, diffable, versioned
- Large binary data referenced, not embedded in JSON
- Format version field required from first save implementation

## MVP constraints

- Fixed BPM (no tempo map)
- Arrangement-first (session/clip launcher later)
- MIDI clips before audio clips in priority

## Flutter projection

Flutter caches a read-only snapshot for UI:

- track list, clip regions, device chain summary, parameter values
- Updated via engine events, not by duplicating mutation logic in Dart
