# Feature Brief: Time‑Based Effects Suite

## User‑visible goal

Add a unified **Time‑Based Effects Suite** to the DAW, giving users four high‑quality audio processors – **Delay**, **Reverb**, **Chorus**, and **Phaser** – that can be added to any track/device chain. Each effect appears in the Flutter device picker, provides a compact mobile‑first UI, and persists its parameters in project JSON. Users can enable/disable each effect, tweak parameters, automate them, and hear the result instantly.

## Non‑goals

- No implementation of new DSP algorithms beyond what JUCE already provides.
- No multi‑channel (e.g., surround) processing – all effects operate on mono/stereo buffers.
- No built‑in preset library (future work).
- No integration with external VST/AU hosts.
- No modification of existing non‑time‑based device code.

## Demo script (PO acceptance)

1. User opens the **Device Picker** → sees entries **Delay**, **Reverb**, **Chorus**, **Phaser**.
2. User adds **Delay** to a track → a Delay card appears with a header showing the effect name and an enable toggle.
3. User expands the Delay UI, changes **Time**, **Feedback**, **Mix** → audio output reflects the changes in real time.
4. User adds **Reverb** after Delay, adjusts **Room Size** and **Damping** → the chain processes correctly (Delay → Reverb).
5. User records automation on **Delay → Mix** → playback reproduces the automation.
6. User saves the project → reload → the full effect chain and all parameters are restored.

## Existing code to reuse

- `juce::dsp::DelayLine<float>` – already used in other experimental devices.
- `juce::Reverb` – JUCE’s built‑in reverb implementation.
- `juce::dsp::Chorus<float>` – existing chorus class.
- `juce::dsp::Phaser<float>` – existing phaser class.
- Engine host infrastructure (`EngineHost`, `DeviceRegistry`, `IDeviceType`, `DeviceVariantParams`).
- Flutter bridge pattern: `MethodChannel` calls defined in `engine_bridge.dart` and native C++ side in `NativeBridge.cpp`.
- JSON handling utilities (`juce::var`, `juce::DynamicObject`).
