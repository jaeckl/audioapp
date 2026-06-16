# Flutter / Native Bridge

## Overview

The bridge connects Flutter (Dart) to the C++ project/audio engine on Android.

**MVP approach:**

- Flutter `MethodChannel` for commands (Dart → native)
- `EventChannel` for engine events (native → Dart)
- JSON payloads acceptable for early non-realtime commands; keep payloads small

Platform channels are **never** used from the audio thread.

## Channel names

| Channel | Direction | Purpose |
|---------|-----------|---------|
| `com.audioapp.daw/engine` | Dart → native | Commands |
| `com.audioapp.daw/events` | native → Dart | State/events |

## Thread ownership

| Operation | Thread |
|-----------|--------|
| MethodChannel handler | Platform UI / JNI thread |
| Command validation & graph build | Engine control thread |
| Event emission to Flutter | Main thread / dedicated worker |
| Audio processing | JUCE audio thread |

## Command API (planned)

Commands are invoked as `invokeMethod` with a method name and optional JSON map.

| Command | Status | Description |
|---------|--------|-------------|
| `ping` | Milestone 00 | Connectivity check |
| `play` | Milestone 01 | Start transport / test tone |
| `stop` | Milestone 01 | Stop transport |
| `createProject` | Milestone 02 | New project |
| `addTrack` | Milestone 02 | Add arrangement track |
| `selectTrack` | Milestone 02 | Selection |
| `addDeviceToTrack` | Milestone 02 | Append device to chain |
| `setDeviceParameter` | Milestone 02 | Set parameter by id |
| `createMidiClip` | Milestone 03 | Create clip on track |
| `saveProject` | Milestone 05 | Save to path |
| `loadProject` | Milestone 05 | Load from path |

### Example (Dart)

```dart
await engineChannel.invokeMethod('play');
await engineChannel.invokeMethod('setDeviceParameter', {
  'deviceId': 'dev-001',
  'parameterId': 'frequency',
  'value': 440.0,
});
```

### Example (response)

Success: `null` or structured map.  
Failure: `PlatformException` with `code`, `message`, optional `details`.

## Event API (planned)

Events stream as maps on `EventChannel`:

| Event | Frequency | Payload |
|-------|-----------|---------|
| `transport` | Throttled (~15–30 Hz) | `{ playing, playheadBeats, bpm }` |
| `projectSnapshot` | On change | Compact project summary |
| `error` | On error | `{ code, message }` |

High-frequency data must be throttled and coalesced before sending to Dart.

## Serialization

- MVP: JSON strings for commands and small snapshots
- Near-term: typed schema + binary snapshots for large state

## Versioning

Bridge API version `1` (initial). Breaking changes increment version and are documented in ADRs.

## Realtime safety

1. Audio callback never calls into Flutter or JNI.
2. Commands queue to the engine; graph swaps at safe points.
3. Events originate from non-audio threads only.

## Error handling

- Invalid commands return structured errors without crashing the engine.
- Engine fatal errors emit `error` event and stop transport safely.

## Examples (Milestone 01 target)

```text
User taps Play
  → Dart invokeMethod('play')
  → Bridge enqueues start
  → Engine enables test oscillator on audio graph
  → Audio thread outputs tone
  → Event stream sends { playing: true }
```
