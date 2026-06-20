# Milestone 16 — Modulation & Automation Test Coverage

**ADR:** N/A (tests only, no new architecture)
**Contract docs:** [docs/features/modulation-automation-test-coverage/](../../docs/features/modulation-automation-test-coverage/)

## Story order (all implementable in parallel)

| # | Ticket | File | Type |
|---|--------|------|------|
| 1 | **US-16-01** | `engine_juce/tests/stacked_lfo_modulation_test.cpp` | C++ engine E2E |
| 2 | **US-16-02** | `engine_juce/tests/effect_device_modulation_test.cpp` | C++ engine E2E |
| 3 | **US-16-03** | `engine_juce/tests/common_param_modulation_test.cpp` | C++ engine E2E |
| 4 | **US-16-04** | `engine_juce/tests/percussion_modulation_test.cpp` | C++ engine E2E |
| 5 | **US-16-05** | `engine_juce/tests/adsr_modulator_test.cpp` | C++ engine E2E |
| 6 | **US-16-06** | `engine_juce/tests/lfo_polarity_test.cpp` | C++ engine E2E |
| 7 | **US-16-07** | `engine_juce/tests/lfo_sync_bpm_test.cpp` | C++ engine E2E |
| 8 | **US-16-08** | `engine_juce/tests/gain_pan_mod_auto_test.cpp` | C++ engine E2E |
| 9 | **US-16-09** | `engine_juce/tests/effect_device_automation_test.cpp` | C++ engine E2E |
| 10 | **US-16-10** | `app_flutter/test/lfo_bridge_test.dart` | Flutter unit |
| 11 | **US-16-11** | `app_flutter/test/modulation_widget_test.dart` | Flutter widget |
| 12 | **US-16-12** | `app_flutter/test/lfo_snapshot_parsing_test.dart` | Flutter unit |
| 13 | **US-16-13** | `app_flutter/test/modulation_persistence_test.dart` | Flutter unit |

## Coverage gaps closed

- Stacked modulation (2+ LFOs on same param)
- Effect device modulation (Compressor, Gate, Expander, Limiter)
- Common parameter gain/pan modulation
- Percussion generator modulation (Kick, Snare, Clap, Crash, Cymbal)
- ADSR/ADR envelope modulators
- LFO polarity (bipolar, positive-only, negative-only)
- LFO sync-to-BPM
- Combined modulation + automation on gain/pan
- Effect device automation
- Flutter LFO bridge CRUD (createLfo, removeLfo, etc.)
- Flutter modulation widget rendering
- Flutter LFO/ModulationEdge snapshot parsing
- Flutter modulation persistence save/load

## Zero production code changes

All 13 packages are test-only files. No CMakeLists.txt, no .dart files in lib/, no engine source files were modified.
