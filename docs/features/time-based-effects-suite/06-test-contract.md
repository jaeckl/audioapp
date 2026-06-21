# Test Contract for Time-Based Effects Suite (WP-6)

## 1. Brief description
The test suite validates the correct behaviour of the four time‑based effect devices – **Delay**, **Reverb**, **Chorus**, and **Phaser** – and ensures that the Flutter UI correctly interacts with the native engine via the MethodChannel bridge. The suite is split into C++ unit tests for the engine and a Flutter widget test that exercises the UI‑engine integration.

## 2. Canonical vocabulary
| Concept | Canonical name | Type / file | Notes |
|---------|----------------|------------|-------|
| Delay effect unit test | `EffectDelayTest` | C++ (`engine_juce/tests/effect_delay_test.cpp`) | Tests creation, parameter setting, snapshot round‑trip |
| Reverb effect unit test | `EffectReverbTest` | C++ (`engine_juce/tests/effect_reverb_test.cpp`) | Same pattern as Delay |
| Chorus effect unit test | `EffectChorusTest` | C++ (`engine_juce/tests/effect_chorus_test.cpp`) | |
| Phaser effect unit test | `EffectPhaserTest` | C++ (`engine_juce/tests/effect_phaser_test.cpp`) | |
| UI integration test | `EffectUITest` | Flutter (`app_flutter/test/effect_ui_test.dart`) | Verifies widget rendering, slider interaction, MethodChannel calls |

## 3. API contracts used in tests
### `DeviceRegistry::createDefault(std::string_view typeId) -> DeviceSlot`
- **Signature**: `DeviceSlot DeviceRegistry::createDefault(std::string_view typeId)`
- **Inputs**: `typeId` – one of `"delay"`, `"reverb"`, `"chorus"`, `"phaser"` (case‑sensitive).
- **Outputs**: Returns a `DeviceSlot` object that holds the newly created device instance.
- **Threading model**: Must be called from the **control thread**. The returned slot is safe to query from any thread, but parameter changes must go through the slot’s API which forwards to the audio thread.
- **Error handling**: Throws `std::invalid_argument` if `typeId` is unknown. Callers should catch and treat as a test failure.

### `DeviceRegistry::setParameter(DeviceSlot&, const String& paramId, float value) -> DeviceParameterResult`
- **Signature**: `DeviceParameterResult DeviceRegistry::setParameter(const DeviceSlot& slot, const String& paramId, float value)`
- **Inputs**: `slot` – a valid device slot; `paramId` – name of the parameter defined in the device’s parameter struct; `value` – clamped to the parameter’s valid range.
- **Outputs**: `DeviceParameterResult` with a boolean `handled` flag.
- **`handled` semantics**: `true` indicates the parameter was recognised and applied; `false` indicates unknown `paramId` or value rejected.
- **Threading**: Must be called on the **control thread**; the implementation forwards to the audio thread safely.
- **Error handling**: No exceptions; callers inspect `handled`.

### `DeviceRegistry::setStringParameter(DeviceSlot&, const String& paramId, const String& value) -> DeviceParameterResult`
- Same semantics as `setParameter` but for string‑typed parameters (e.g., preset name). `handled` flag semantics identical.

### `DeviceRegistry::find(std::string_view typeId) -> std::optional<DeviceSlot>`
- **Signature**: `std::optional<DeviceSlot> DeviceRegistry::find(std::string_view typeId)`
- **Inputs**: `typeId` as above.
- **Outputs**: Optional slot; empty if no device of that type exists.
- **Threading**: Control thread.
- **Error handling**: No exception; returns `std::nullopt` when not found.

### `DeviceParameterResult::handled`
- A `bool` indicating whether the requested parameter operation succeeded. Tests assert `true` for valid parameters and `false` for invalid ones.

## 4. Test contract
### Required test files and locations
| Language | File | Purpose |
|----------|------|---------|
| C++ | `engine_juce/tests/effect_delay_test.cpp` | Verify Delay device creation, default snapshot, parameter set, and round‑trip JSON.
| C++ | `engine_juce/tests/effect_reverb_test.cpp` | Same for Reverb.
| C++ | `engine_juce/tests/effect_chorus_test.cpp` | Same for Chorus.
| C++ | `engine_juce/tests/effect_phaser_test.cpp` | Same for Phaser.
| Dart/Flutter | `app_flutter/test/effect_ui_test.dart` | End‑to‑end widget test covering UI strip, panel, slider interaction, and MethodChannel bridge.

### Naming conventions & test case structure
- Test class names must match the canonical names above and be defined with the GoogleTest `TEST` macro, e.g. `TEST(EffectDelayTest, CreateAndSnapshot)`.
- Each test file contains **at least three** test cases:
  1. **Creation & type verification** – `DeviceRegistry::createDefault` returns a slot whose type matches the expected string.
  2. **Parameter setting** – Call `setParameter`/`setStringParameter` and assert `DeviceParameterResult::handled == true`; then retrieve snapshot and verify the field value.
  3. **Round‑trip snapshot** – Serialize the device to JSON via `EffectSnapshot`, deserialize back, and assert all fields equal the original defaults.

#### Flutter widget test expectations (updated)
- The test will locate the `EffectDeviceStrip` widget by its displayed effect name using `find.text('Delay')` (or the appropriate effect name).
- Sliders are located by searching for `Slider` widgets within the strip; the first slider found will be used for interaction.
- The enable toggle is located by searching for a `Switch` widget inside the strip.
- No reliance on explicit `Key` identifiers is required, allowing the test to work with the current UI implementation.
- The test sets up a mock `MethodChannel` (`engine/effect`) that records calls and returns successful responses.
- After interacting with a slider or toggle, the test verifies that the mock handler received the expected method name (`setEffectParameter` or `enableEffect`).

### Integration with test harnesses
- **C++**: Tests are compiled into the `audioapp_engine_tests` target (currently a separate executable). They must be linked against the static engine library (`libaudioapp_engine.a`) and use the existing GoogleTest framework configured in `engine_juce/CMakeLists.txt`.
- **Flutter**: The test is executed by `flutter test` in the `app_flutter` directory. It requires the bridge’s MethodChannel mock to be injected via `MethodChannel.setMockMethodCallHandler` before `runApp`.
- **Setup/Teardown**:
  * C++: Each test creates a fresh `DeviceRegistry` instance, registers built‑in devices (`DeviceRegistry::createBuiltIn()`), and registers time‑based effects via `registerTimeBasedEffects(registry)`.
  * Flutter: `setUpAll` registers the mock channel; `tearDownAll` clears it.

### Coverage goals
- **C++**: Minimum **80 %** line coverage for all new files (`DelayParams.hpp`, `ReverbParams.hpp`, etc.) measured by `gcov`/`lcov` in CI.
- **Flutter**: Minimum **80 %** widget test coverage for the effect UI files measured by `flutter test --coverage`.
- No linter warnings (`clang‑tidy`, `flutter analyze`) in the new test files.

## 5. File ownership table entry
| File/path | Owner work package | Allowed changes | Forbidden changes |
|-----------|-------------------|-----------------|-------------------|
| `engine_juce/tests/effect_delay_test.cpp` | `effects-unit-tests` | Add/modify test code, includes, asserts | Modify production headers or implementation files |
| `engine_juce/tests/effect_reverb_test.cpp` | `effects-unit-tests` | Same as above | Same as above |
| `engine_juce/tests/effect_chorus_test.cpp` | `effects-unit-tests` | Same as above | Same as above |
| `engine_juce/tests/effect_phaser_test.cpp` | `effects-unit-tests` | Same as above | Same as above |
| `app_flutter/test/effect_ui_test.dart` | `effects-unit-tests` | Test code only | Production UI files |

## 6. Acceptance criteria
1. All five test files compile without errors on **Windows (MSVC)** and **Linux (gcc)**.
2. CI runs `cmake --build` → `ctest` for C++ tests and `flutter test` for Dart tests; all tests pass.
3. Code coverage report shows **≥ 80 %** for the newly‑added engine code and UI widget code.
4. No linter warnings (`clang‑tidy` for C++, `flutter analyze` for Dart) in any of the new test files.
5. The test suite must be runnable independently of production code changes – i.e., it only depends on the contracts produced by WP‑1 – WP‑5.

## 7. Dependencies & execution order
- **Must run after**: WP‑1 (engine registration), WP‑2 (parameter structs), WP‑3 (concrete device implementations), WP‑4 (Flutter bridge), WP‑5 (Flutter UI).
- **Rationale**: The tests require concrete device classes, the registration helper, and the UI bridge to exist. The contract stubs generated in WP‑1 & WP‑2 are sufficient for compilation, but functional verification needs the full implementations.

---
*Generated by the Feature Contract Architect subagent.*