# OOP Device Processors — Integration & Verification Plan

This document details the step-by-step integration procedure, compile gating, and snapshot verification steps to prevent regressions.

## Step 1: Pre-Refactor Baseline Capture

Before modifying any source code, we must generate and verify the baseline test-gate binary:
1. Ensure the project is compiled:
   ```bash
   python tools/step_gate.py
   ```
2. Capture the baseline test snapshot:
   ```bash
   python tools/snapshot_test.py docs/features/oop-device-processors/baseline.txt
   ```
   This baseline captures all assertions, peak outputs, and results of `device_chain_test.cpp`.

## Step 2: Code Stub Creation

To allow parallel implementation by multiple subagents without causing file compilation breakages:
- The orchestrator can optionally generate empty stubs (matching the signatures from `03-api-contracts.md`) for all 22 device processors under `engine_juce/include/audioapp/devices/processors/`.
- This ensures all `#include` declarations in `DeviceChainProcessor.hpp` compile cleanly.

## Step 3: Iterative Migration (Vertical Slice Integration)

Each work package must be merged and integrated in order:

1. **Package 1 (Base & TrackGain)**:
   - Extract common utility helpers (like `stereoBlockPeak`, etc.) and `TrackGainProcessor`.
   - Update `DeviceChainProcessor.cpp` `TrackGain` case statement to call the new processor.
   - Run compilation check: `python tools/step_gate.py`.
   - Validate regression: `python tools/snapshot_test.py build/engine/test_gate/post_step1.txt`. Compare with baseline.

2. **Package 2 (Synthesizers & Instruments)**:
   - Implement `Oscillator`, `Sampler`, `SubtractiveSynth`, `BassSynth`, and `PhaseModSynth` processors.
   - Link them into `DeviceChainProcessor.cpp` switch case.
   - Run compilation and snapshot regression comparison.

3. **Package 3 (Percussion Generators)**:
   - Implement `Kick`, `Snare`, `Clap`, `Cymbal`, and `Crash` processors.
   - Link them into `DeviceChainProcessor.cpp` switch case.
   - Run compilation and snapshot regression comparison.

4. **Package 4 (Dynamics Effects)**:
   - Implement `Gate`, `Compressor`, `Expander`, and `Limiter` processors.
   - Link them into `DeviceChainProcessor.cpp` switch case.
   - Run compilation and snapshot regression comparison.

5. **Package 5 (Time-Based Effects)**:
   - Implement `Delay`, `Reverb`, `Chorus`, and `Phaser` processors.
   - Link them into `DeviceChainProcessor.cpp` switch case.
   - Run compilation and snapshot regression comparison.

6. **Package 6 (Frequency FX)**:
   - Implement `Filter`, `FourBandEq`, and `FrequencyShifter` processors.
   - Link them into `DeviceChainProcessor.cpp` switch case.
   - Run compilation and snapshot regression comparison.

## Step 4: Final Clean-up and Verification

After all 22 devices are migrated to modular files:
1. Prune all unused helper functions and dead-code blocks from `DeviceChainProcessor.cpp`.
2. Ensure `DeviceChainProcessor.cpp` conforms to the <250 LOC hard trigger limit.
3. Perform a final full integration snapshot run:
   ```bash
   python tools/snapshot_test.py docs/features/oop-device-processors/final_refactor.txt
   ```
4. Confirm bitwise equivalence:
   ```powershell
   Compare-Object (Get-Content docs/features/oop-device-processors/baseline.txt) (Get-Content docs/features/oop-device-processors/final_refactor.txt)
   ```
   The comparison must show zero differences.
