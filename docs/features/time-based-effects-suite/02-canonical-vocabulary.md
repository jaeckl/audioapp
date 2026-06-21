# Canonical Vocabulary

| Concept          | Canonical name       | Type / File                              | Notes |
|------------------|----------------------|------------------------------------------|-------|
| Effect type      | EffectType           | `engine_juce/include/audioapp/effects/EffectTypes.hpp` | Enum values: `Delay`, `Reverb`, `Chorus`, `Phaser` |
| Delay parameters | DelayParams          | `engine_juce/include/audioapp/effects/DelayParams.hpp` | All delay‑specific fields |
| Reverb parameters| ReverbParams         | `engine_juce/include/audioapp/effects/ReverbParams.hpp` | JUCE `Reverb::Parameters` mapping |
| Chorus parameters| ChorusParams         | `engine_juce/include/audioapp/effects/ChorusParams.hpp` | JUCE `dsp::Chorus` mapping |
| Phaser parameters| PhaserParams         | `engine_juce/include/audioapp/effects/PhaserParams.hpp` | JUCE `dsp::Phaser` mapping |
| Effect device    | TimeBasedEffectDeviceType | `engine_juce/src/effects/TimeBasedEffectDeviceType.cpp` | Base class for the four devices |
| UI panel widget  | EffectPanel          | `app_flutter/lib/effects/<effect>_panel.dart` | Flutter widget for each effect |
| Device strip widget | EffectDeviceStrip   | `app_flutter/lib/effects/effect_device_strip.dart` | Compact card shown in chain view |
| JSON snapshot    | EffectSnapshot       | `engine_juce/include/audioapp/effects/EffectSnapshot.hpp` | Serialized representation stored in project JSON |
| Method channel name | "engine/effect"   | `app_flutter/lib/engine_bridge.dart` | Bridge used for get/set calls |
