# API Contracts

## C++ Engine API (exposed via Device Registry)

| Function / Method | Owner Module | Input | Output | Thread | Description |
|-------------------|--------------|-------|--------|--------|-------------|
| `TimeBasedEffectDeviceType::createDefault(const std::string& type)` | `engine_juce/src/effects/` | `type` (enum `EffectType`) | `DeviceSlot` with effect instance | Control | Creates a new effect device with default parameters for the given type. |
| `TimeBasedEffectDeviceType::setParameter(const std::string& paramName, float value)` | `engine_juce/src/effects/` | `paramName`, `value` | `bool` success | Control | Validates and stores the parameter in the snapshot. |
| `TimeBasedEffectDeviceType::enable(bool)` | same | enable flag | `void` | Control | Toggles effect on/off. |
| `TimeBasedEffectDeviceType::toSnapshotState()` | same | – | `EffectSnapshot` (JSON‑compatible struct) | Control | Serializes current parameters to a snapshot. |
| `TimeBasedEffectDeviceType::slotFromSnapshot(const EffectSnapshot&)` | same | snapshot | `DeviceSlot` | Control | Deserializes snapshot back into a device slot. |
| `EffectDeviceStrip::buildPlaybackNode(const EffectSnapshot&)` | `engine_juce/src/effects/` | snapshot | `DeviceNodePlayback` | Audio | Creates the audio‑thread node that holds the JUCE DSP instance and copies snapshot atomically. |
| `EffectDeviceStrip::processBlock(AudioBuffer<float>&)` | same | audio buffer | – | Audio | Calls the underlying JUCE DSP `process` method each block. |

## Flutter Bridge API (MethodChannel `engine/effect`)

| Method name | Parameters | Return | Description |
|-------------|------------|--------|-------------|
| `getEffectSnapshot` | `{trackId: int, deviceIndex: int}` | `{type: string, params: object}` | Returns the current snapshot for the effect device at the given location. |
| `setEffectParameter` | `{trackId: int, deviceIndex: int, paramName: string, value: double}` | `bool` success | Updates a single parameter on the effect device. |
| `enableEffect` | `{trackId: int, deviceIndex: int, enabled: bool}` | `bool` | Enables or disables the effect. |
| `addEffect` | `{trackId: int, effectType: string}` | `{deviceIndex: int}` | Instantiates a new effect device of the given type in the track chain. |
| `removeEffect` | `{trackId: int, deviceIndex: int}` | `bool` | Removes the effect from the chain. |

## Event / Notification API

- `EffectParameterChanged` – emitted from native bridge when a param changes; payload `{trackId, deviceIndex, paramName, value}`.
- `EffectEnabledChanged` – payload `{trackId, deviceIndex, enabled}`.
