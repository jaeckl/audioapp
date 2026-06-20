# File Ownership

## Engine test files (owner: `engine_juce/tests/`)

Only these files may be created/modified by engine-side work packages.

| File | Owner Package | Allowed changes | Forbidden changes |
| ---- | ------------- | --------------- | ----------------- |
| `engine_juce/tests/stacked_lfo_modulation_test.cpp` | WP-01 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/effect_device_modulation_test.cpp` | WP-02 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/common_param_modulation_test.cpp` | WP-03 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/percussion_modulation_test.cpp` | WP-04 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/adsr_modulator_test.cpp` | WP-05 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/lfo_polarity_test.cpp` | WP-06 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/lfo_sync_bpm_test.cpp` | WP-07 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/gain_pan_mod_auto_test.cpp` | WP-08 | Create file, implement tests | Modifying production code |
| `engine_juce/tests/effect_device_automation_test.cpp` | WP-09 | Create file, implement tests | Modifying production code |

## Flutter test files (owner: `app_flutter/test/`)

| File | Owner Package | Allowed changes | Forbidden changes |
| ---- | ------------- | --------------- | ----------------- |
| `app_flutter/test/lfo_bridge_test.dart` | WP-10 | Create file, implement tests | Modifying production code |
| `app_flutter/test/modulation_widget_test.dart` | WP-11 | Create file, implement tests | Modifying production code |
| `app_flutter/test/lfo_snapshot_parsing_test.dart` | WP-12 | Create file, implement tests | Modifying production code |
| `app_flutter/test/modulation_persistence_test.dart` | WP-13 | Create file, implement tests | Modifying production code |

## Forbidden file modifications (all packages)

- Any file in `engine_juce/src/` (production engine code)
- Any file in `engine_juce/include/` (production engine headers)
- Any file in `app_flutter/lib/` (production Flutter code)
- Any file under `native_bridge/`
- `CMakeLists.txt`
- Any workflow/CI configuration

## Shared test helper files

No shared test helper files exist — each test file duplicates the small audio-analysis
helper functions inline. This is the existing convention (see `modulation_e2e_test.cpp`,
`automation_filter_sweep_test.cpp`, `autobroken_routing_test.cpp`, etc.).