# Audio Graph

## Purpose

Route MIDI and audio through tracks, device chains, and the master output in deterministic order.

## Concepts

| Concept | Description |
|---------|-------------|
| `AudioGraph` | Top-level processing graph for the project |
| `Track` | Timeline owner; hosts clips and a device chain |
| `DeviceChain` | Ordered list of devices on a track |
| `Device` | Built-in instrument, effect, or utility node |
| `RoutingNode` | Internal send/receive (minimal in early milestones) |
| `MidiEventBuffer` | Per-block MIDI events, preallocated |
| `AudioBuffer` | Channel-major float buffers, preallocated |

## Processing order (MVP)

1. Transport advances playhead (control thread or block start)
2. MIDI clips on tracks emit events into per-track MIDI buffers
3. Each track's device chain processes MIDI → audio
4. Track outputs summed to master
5. Master limited/clipped as needed

## Graph mutation safety

- **Pending graph**: control thread builds new topology
- **Active graph**: audio thread reads current snapshot
- Swap at block boundary via atomic pointer flip or double buffer
- No allocation during swap on audio thread

## MVP minimal graph

Initial milestone targets:

```text
[ MIDI clip ] → [ Simple Oscillator ] → [ Track out ] → [ Master ]
```

Later:

```text
[ MIDI clip ] → [ Oscillator/Sampler ] → [ Gain ] → [ Pan ] → [ Master ]
```

## Cycle detection

When send/receive routing is added, validate the graph for cycles before activation.

## Testing

- Offline render of known graph → golden sample comparison
- Silence when stopped
- Deterministic output for fixed seed MIDI
