# Ducker — API / Engine Contracts

## Model

```
DuckerModel {
  string sidechainSourceId;  // "" | track-audio:ID | deviceId
  float duckThreshold, duckDepth, duckAttack, duckRelease; // 0..1
}
```

Playback: `DuckerParams` (floats only). Graph rebuild reads `sidechainSourceId` from slot.

## Graph

- Emit `GraphSourceDefinition{sourceId="track-audio:"+trackId}` → last audio device on track.
- Ducker with non-empty source → `GraphReceiverDefinition{sidechain=true, mix=1}`.
- `ProcessorGraphEdge.sidechain=true` does **not** mix into track bus.
- Orchestrator: copy edge buffers into `ProcessContext.sidechainL/R` before `DuckerProcessor::process`.
- `MultipleAudioInputs` counts only `!sidechain` receivers.
- Topology change on `setDeviceStringParameter("sidechainSourceId", …)`; rollback if graph invalid.

## Bridge

- Float: `setDeviceParameter`
- String: `setDeviceStringParameter` (`sidechainSourceId`)
