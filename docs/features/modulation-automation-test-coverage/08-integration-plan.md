# Integration Plan

## Recommended implementation order

All 13 work packages can run in PARALLEL — no package depends on another.

## Parallel execution strategy

```
TIME -->
├── WP-01  stacked_lfo_modulation_test.cpp              │
├── WP-02  effect_device_modulation_test.cpp              │  PARALLEL
├── WP-03  common_param_modulation_test.cpp               │  (all 9 C++
├── WP-04  percussion_modulation_test.cpp                 │   test packages)
├── WP-05  adsr_modulator_test.cpp                        │
├── WP-06  lfo_polarity_test.cpp                          │
├── WP-07  lfo_sync_bpm_test.cpp                          │
├── WP-08  gain_pan_mod_auto_test.cpp                     │
├── WP-09  effect_device_automation_test.cpp              │
│
├── WP-10  lfo_bridge_test.dart                           │  PARALLEL
├── WP-11  modulation_widget_test.dart                    │  (all 4 Flutter
├── WP-12  lfo_snapshot_parsing_test.dart                 │   test packages)
├── WP-13  modulation_persistence_test.dart               │
```

All 13 can be implemented by independent agents simultaneously.

## Integration risks and mitigations

| Risk | Likelihood | Mitigation |
| ---- | ---------- | ---------- |
| Test relies on behavior not yet implemented in engine | Low | All modulation/automation APIs exist and are tested by existing tests |
| Audio analysis threshold too tight (false failures) | Medium | Use generous thresholds (1.5x–2x) like existing tests; tune after first run |
| Percussion modulation detection too weak | Medium | Use RMS comparison vs unmodulated baseline rather than HF energy |
| Sync BPM test flaky due to phase alignment | Low | Count zero-crossings of HF energy derivative rather than exact peak positions |
| Flutter widget tests fail due to theme changes | Low | Widget tests use local `MaterialApp` wrapping; no external theme dependency |
| Compilation issues with new test files | Low | Same includes, patterns, and helpers as 37 existing test files |
| Stacked LFO test has too-close thresholds | Low | Compare stacked-vs-single-LFO ratio; require stacked > single by 1.3x |

## Contract verification checklist

Before merging all packages:

- [ ] All 9 C++ test files compile with `g++ -std=c++20`
- [ ] All 9 C++ test files return `EXIT_SUCCESS`
- [ ] All 4 Dart test files pass `flutter test`
- [ ] No production code files were modified (verify via `git diff --stat`)
- [ ] Each test file has the correct canonical ID in its comments
- [ ] Each test file uses the correct canonical parameter names
- [ ] Flutter mock handlers cover all method calls without returning `null`

## Post-integration verification

1. Run all 37 existing C++ tests to verify no regressions
2. Run all existing Flutter tests: `cd app_flutter && flutter test`
3. New test count: 9 C++ files + 4 Dart files = 13 new files
4. Full engine compilation sanity check: `cmake --build build/engine`

## Summary

| Metric | Value |
| ------ | ----- |
| Total new C++ tests | 9 files (~40 individual test cases) |
| Total new Flutter tests | 4 files (~20 individual test cases) |
| Parallel-safe packages | 13/13 (100%) |
| Sequential dependencies | 0 |
| Production files modified | 0 |
| Integration risk | Low — all use proven patterns and APIs |