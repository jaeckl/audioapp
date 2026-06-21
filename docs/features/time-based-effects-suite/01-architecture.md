# Architecture: Time‑Based Effects Suite

## Overview

The **Time‑Based Effects Suite** adds four new DSP devices – **Delay**, **Reverb**, **Chorus**, and **Phaser** – to the existing JUCE‑based audio engine. Each device is a *wrapper* around a JUCE DSP class (`juce::dsp::DelayLine`, `juce::Reverb`, `juce::dsp::Chorus`, `juce::dsp::Phaser`). The wrapper implements the `IDeviceType` interface used throughout the DAW, making the effects first‑class devices that can be added to any track/device chain.

## Module boundaries

- **engine_juce/src/effects/** – C++ implementations of the four effect device types and shared base class `TimeBasedEffectDeviceType`.
- **engine_juce/include/audioapp/effects/** – Public headers exposing the device factories, parameter structs, and snapshot conversion utilities.
- **native_bridge/effects_bridge.cpp** – Method‑channel bridge that forwards Flutter calls to the C++ side.
- **app_flutter/lib/effects/** – Flutter UI panels (`DelayPanel`, `ReverbPanel`, `ChorusPanel`, `PhaserPanel`) and a generic `EffectDeviceStrip` widget used in the device chain view.
- **app_flutter/lib/engine_bridge.dart** – Updated MethodChannel definitions for effect devices.

## Threading model

- **Control thread** – UI → MethodChannel → `TimeBasedEffectDeviceType` methods (`setParameter`, `enable`, `disable`). Parameter changes are stored in a snapshot object and later converted to the JUCE DSP state.
- **Audio thread** – Each `DeviceNodePlayback` holds an instance of the JUCE DSP class. The `processBlock` method runs on the audio thread, reading the latest parameter snapshot (read‑only) via lock‑free atomic copy.

## Ownership & error model

- Parameter validation (range, enum) is performed on the control thread; invalid values are clamped and an error log is emitted.
- Enabling/disabling an effect that is already in the desired state is a no‑op.
- If an effect device cannot be instantiated (e.g., missing library), the factory returns `nullptr` and the UI shows a disabled placeholder.

## Persistence model

- Each effect device implements `toSnapshotState()` / `slotFromSnapshot()` that convert between a strongly‑typed C++ struct (`DelayParams`, `ReverbParams`, …) and a JSON object using **JUCE JSON utilities**.
- The snapshot is stored in the project file under `track.devices[<index>].effect` with a `type` field (`"delay"`, `"reverb"`, …) and an `params` object.

## UI / state synchronization model

- Flutter reads the full device snapshot via `MethodChannel.invokeMethod('getEffectSnapshot', {trackId, deviceIndex})`.
- UI widgets call `MethodChannel.invokeMethod('setEffectParameter', {trackId, deviceIndex, paramName, value})`.
- The bridge updates the C++ snapshot; the audio thread automatically reads the latest atomically‑copied values.

## Non‑goals

- No multi‑channel (5.1/7.1) processing – all effects work on mono or stereo buffers.
- No new DSP algorithm development – we rely on JUCE’s built‑in implementations.
- No preset library – preset handling is out of scope for this slice.
