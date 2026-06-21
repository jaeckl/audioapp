# File Ownership

| File/path | Owner work package | Allowed changes | Forbidden changes |
|----------|-------------------|-----------------|-------------------|
| `engine_juce/include/audioapp/effects/EffectTypes.hpp` | WP-1 (Engine registration) | Add enum `EffectType` and related helper functions | Modify existing effect enums or other unrelated code |
| `engine_juce/include/audioapp/effects/DelayParams.hpp` | WP-2 (Params structs) | Define `DelayParams` fields, defaults, validation helpers | Change layout of other effect param files |
| `engine_juce/include/audioapp/effects/ReverbParams.hpp` | WP-2 | Define `ReverbParams` | – |
| `engine_juce/include/audioapp/effects/ChorusParams.hpp` | WP-2 | Define `ChorusParams` | – |
| `engine_juce/include/audioapp/effects/PhaserParams.hpp` | WP-2 | Define `PhaserParams` | – |
| `engine_juce/include/audioapp/effects/EffectSnapshot.hpp` | WP-1 | Serialize/deserialize unified snapshot struct | Alter serialization format of other devices |
| `engine_juce/include/audioapp/effects/TimeBasedEffectDeviceType.hpp` | WP-3 (Device implementation) | Base class and common logic | Implement effect‑specific DSP code here (should be in WP-3 sub‑packages) |
| `engine_juce/src/effects/DelayDeviceType.cpp` | WP-3‑Delay | Implement Delay device using `juce::dsp::DelayLine` | Touch other effect source files |
| `engine_juce/src/effects/ReverbDeviceType.cpp` | WP-3‑Reverb | Implement Reverb device using `juce::Reverb` | – |
| `engine_juce/src/effects/ChorusDeviceType.cpp` | WP-3‑Chorus | Implement Chorus device using `juce::dsp::Chorus` | – |
| `engine_juce/src/effects/PhaserDeviceType.cpp` | WP-3‑Phaser | Implement Phaser device using `juce::dsp::Phaser` | – |
| `engine_juce/src/effects/EffectDeviceStrip.cpp` | WP-1 (Playback node) | Build playback node from snapshot, route audio | Change processing order of other devices |
| `native_bridge/effects_bridge.cpp` | WP-5 (Flutter bridge) | MethodChannel implementations for get/set/add/remove | Modify unrelated native bridge code |
| `app_flutter/lib/effects/delay_panel.dart` | WP-4‑Delay UI | UI layout, knobs, enable toggle for Delay | Change core engine bridge calls |
| `app_flutter/lib/effects/reverb_panel.dart` | WP-4‑Reverb UI | – | – |
| `app_flutter/lib/effects/chorus_panel.dart` | WP-4‑Chorus UI | – | – |
| `app_flutter/lib/effects/phaser_panel.dart` | WP-4‑Phaser UI | – | – |
| `app_flutter/lib/effects/effect_device_strip.dart` | WP-4 (Common strip) | Card UI for any effect device | Alter device‑picker logic |
| `app_flutter/lib/engine_bridge.dart` | WP-5 | Add method‑channel method names for effects | Remove existing engine bridge methods |
| `engine_juce/tests/effect_delay_test.cpp` | WP-6 (Engine tests) | Unit tests for Delay processing and parameter clamping | Change production code |
| `engine_juce/tests/effect_reverb_test.cpp` | WP-6 | – | – |
| `engine_juce/tests/effect_chorus_test.cpp` | WP-6 | – | – |
| `engine_juce/tests/effect_phaser_test.cpp` | WP-6 | – | – |
| `app_flutter/test/effect_ui_test.dart` | WP-6 (Flutter widget tests) | Verify UI‑bridge round‑trip, knob interaction, enable toggle | – |
