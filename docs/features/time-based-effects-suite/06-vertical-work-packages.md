# Vertical Work Packages: Time‑Based Effects Suite

## Package WP‑1: Engine registration & unified effect base (c++ registration end‑to‑end)

**User‑visibility**: The engine can create a new effect device of a given type via the `DeviceRegistry` and round‑trip its JSON snapshot.

**Assigned files**:
- `engine_juce/include/audioapp/effects/EffectTypes.hpp` (add `EffectType` enum)
- `engine_juce/include/audioapp/effects/TimeBasedEffectDeviceType.hpp` (create base class)
- `engine_juce/src/effects/TimeBasedEffectDeviceType.cpp` (implementation)
- `engine_juce/include/audioapp/DeviceRegistry.hpp` (register each effect device)
- `engine_juce/src/DeviceRegistry.cpp` (modify registration logic)
- `engine_juce/include/audioapp/effects/EffectSnapshot.hpp` (unified snapshot struct)

**Canonical names used**: `EffectType`, `TimeBasedEffectDeviceType`, `EffectSnapshot`.

**API contracts used**: `DeviceRegistry::addBuiltIn`, `createDefault`, `toSnapshotState`, `slotFromSnapshot`.

**Dependencies**: None (foundational).

**Acceptance criteria**:
1. `DeviceRegistry::addBuiltIn<DelayDeviceType>()` etc registers all four effects.
2. `DeviceRegistry::createDefault("delay")` returns a slot whose `toSnapshotState().type == "delay"`.
3. Serialising and deserialising via `EffectSnapshot` round‑trips all default parameters.
4. Engine bridge can query `getEffectSnapshot` for any newly created device.

**Parallel‑safe**: YES – other packages can start after this stub exists.

---

## Package WP‑2: Effect parameter structs & JSON schema (C++ DTO)

**User‑visibility**: Each effect device stores its parameters in a strongly‑typed struct that is serialised to JSON.

**Assigned files**:
- `engine_juce/include/audioapp/effects/DelayParams.hpp`
- `engine_juce/include/audioapp/effects/ReverbParams.hpp`
- `engine_juce/include/audioapp/effects/ChorusParams.hpp`
- `engine_juce/include/audioapp/effects/PhaserParams.hpp`
- `engine_juce/src/effects/EffectSnapshot.cpp` (adds variant handling)

**Canonical names used**: `DelayParams`, `ReverbParams`, `ChorusParams`, `PhaserParams`.

**API contracts used**: Validation helpers, default constructors, `toJson()` / `fromJson()`.

**Dependencies**: WP‑1 (snapshot container must exist).

**Acceptance criteria**:
1. Each struct contains fields exactly matching the JSON schema defined in `04-data-contracts.md`.
2. `EffectSnapshot` can hold any of the four param structs via a `std::variant`.
3. Out‑of‑range values are clamped on `setParameter` and logged.
4. Unit tests (WP‑6) verify serialization/deserialization for each struct.

**Parallel‑safe**: YES – once WP‑1 stubs are present.

---

## Package WP‑3: Concrete effect device implementations (C++)

**User‑visibility**: The engine can process audio through Delay, Reverb, Chorus, and Phaser devices.

**Assigned files**:
- `engine_juce/src/effects/DelayDeviceType.cpp`
- `engine_juce/src/effects/ReverbDeviceType.cpp`
- `engine_juce/src/effects/ChorusDeviceType.cpp`
- `engine_juce/src/effects/PhaserDeviceType.cpp`
- `engine_juce/include/audioapp/effects/DelayDeviceType.hpp` (and similar headers for each)

**Canonical names used**: `DelayDeviceType`, `ReverbDeviceType`, `ChorusDeviceType`, `PhaserDeviceType`.

**API contracts used**: Inherit from `TimeBasedEffectDeviceType`; implement `buildPlaybackNode`, `setParameter`, `enable`.

**Dependencies**: WP‑1, WP‑2.

**Acceptance criteria**:
1. Each device builds a `DeviceNodePlayback` that holds the appropriate JUCE DSP object (`juce::dsp::DelayLine`, `juce::Reverb`, etc.).
2. Parameter changes via `setParameter` immediately affect the DSP state (checked with a unit test that processes a short buffer).
3. Enabling/disabling a device toggles DSP processing without reallocating.
4. No crashes when the device is placed anywhere in a track chain.

**Parallel‑safe**: NO – must follow WP‑1 and WP‑2.

---

## Package WP‑4: Flutter bridge for effect devices (MethodChannel)

**User‑visibility**: Flutter UI can add, remove, enable, and change parameters of any effect.

**Assigned files**:
- `native_bridge/effects_bridge.cpp`
- `app_flutter/lib/engine_bridge.dart` (add method‑channel handlers for `engine/effect`)

**Canonical names used**: Bridge method names `addEffect`, `removeEffect`, `enableEffect`, `setEffectParameter`, `getEffectSnapshot`.

**API contracts used**: Calls to `DeviceRegistry` and `TimeBasedEffectDeviceType` on the C++ side.

**Dependencies**: WP‑1 (device registration) and WP‑3 (device implementations).

**Acceptance criteria**:
1. Adding an effect via `addEffect` creates the device and returns the correct `deviceIndex`.
2. `setEffectParameter` updates the corresponding field in the snapshot and the audio thread reflects the change.
3. `enableEffect` toggles processing without needing a full rebuild.
4. Errors are returned as boolean false and produce a toast in the UI.

**Parallel‑safe**: NO – must wait for WP‑3.

---

## Package WP‑5: Flutter UI – device strip and effect panels (end‑to‑end UI)

**User‑visibility**: Users can see a compact strip for each effect in the track chain, expand a full‑screen panel, adjust knobs/sliders, and record automation.

**Assigned files**:
- `app_flutter/lib/effects/effect_device_strip.dart`
- `app_flutter/lib/effects/delay_panel.dart`
- `app_flutter/lib/effects/reverb_panel.dart`
- `app_flutter/lib/effects/chorus_panel.dart`
- `app_flutter/lib/effects/phaser_panel.dart`
- `app_flutter/lib/effects/effect_panel_base.dart` (shared UI helpers)

**Canonical names used**: `EffectDeviceStrip`, `DelayPanel`, `ReverbPanel`, `ChorusPanel`, `PhaserPanel`.

**API contracts used**: MethodChannel calls defined in WP‑4.

**Dependencies**: WP‑4 (bridge) and WP‑2 (parameter definitions).

**Acceptance criteria**:
1. Device picker lists all four effects with correct icons.
2. Adding an effect inserts a strip with an enable toggle.
3. Expanding a strip opens the matching panel; all knobs map 1:1 to the JSON fields.
4. Real‑time audio feedback is heard within 50 ms of knob movement.
5. Automation button opens the curve editor and saves data under `automation` in the snapshot.
6. All UI elements meet WCAG 2.1 AA accessibility criteria.

**Parallel‑safe**: YES – UI can be mocked against contract stubs before the engine implementation is finished.

---

## Package WP‑6: effects-unit-tests – Tests (engine unit tests + Flutter widget tests)

**User‑visibility**: CI validates correctness of the effect suite.

**Assigned files**:
- `engine_juce/tests/effect_delay_test.cpp`
- `engine_juce/tests/effect_reverb_test.cpp`
- `engine_juce/tests/effect_chorus_test.cpp`
- `engine_juce/tests/effect_phaser_test.cpp`
- `app_flutter/test/effect_ui_test.dart`

**Canonical names used**: Same as implementation files.

**API contracts used**: All public APIs from WP‑1‑5.

**Acceptance criteria**:
1. All C++ tests compile and pass on Windows (MSVC) and Linux (gcc).
2. Flutter widget tests verify that adding an effect shows the strip, that knobs call the bridge, and that the enable toggle updates state.
3. Test coverage ≥ 80 % for new code.

**Parallel‑safe**: YES – test contracts can be written immediately after the API contracts.

---

## Package WP‑INT: Integration & manual verification

**User‑visibility**: Final end‑to‑end verification on a physical device.

**Tasks**:
1. Build the C++ engine (`cmake --build build/engine --target audioapp_engine`).
2. Build the Flutter APK (`cd app_flutter && flutter build apk --debug`).
3. Install on a connected Android device.
4. Run the demo script from the feature brief (add each effect, adjust parameters, record automation, save/load).
5. Verify no crashes, correct audio routing, and UI/bridge stability.
6. Fix any integration issues uncovered.

**Dependencies**: All previous work packages.

**Parallel‑safe**: NO – last step after everything else.
