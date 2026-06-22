# OOP Device Processors — Test Contract

This document outlines the testing strategy, verification steps, and regression checks required to validate that each of the OOP device processors matches the baseline monolithic behavior.

## Core Testing Strategies

### 1. Verification of No-Allocation Rules

Since all code executes on the audio thread, it is critical to verify that there are **no dynamic memory allocations**.
- We will inspect the generated code to ensure there are no `std::vector` modifications, `std::string` formatting, or usage of `new`/`delete` inside the processing loop.
- Any standard C++ containers used within the processors must be completely preallocated or value-allocated on the stack (POD structs).

### 2. Integration & Verification Pipeline

We will utilize the existing test-gate framework to build and run the test suite:
1. **Compilation Check**: Run `python tools/step_gate.py` to compile and link `device_chain_test.exe`.
2. **Behavioral Integrity**: Verify that the tests inside `engine_juce/tests/device_chain_test.cpp` pass completely.
3. **Audio Snapshot Equivalence**: Run `python tools/snapshot_test.py` to compare output streams and verify byte-identical performance against baseline measurements.

## Test Matrix

| Work Package | Target Component | Test Coverage Location | Verification Command |
| :--- | :--- | :--- | :--- |
| Package 1 | `TrackGainProcessor` | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |
| Package 2 | Synthesizers | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |
| Package 3 | Percussion | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |
| Package 4 | Dynamics | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |
| Package 5 | Time-Based | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |
| Package 6 | Frequency FX | `DeviceChainTest` in `device_chain_test.cpp` | `python tools/step_gate.py` |

## Code Review Acceptance Rules

Each newly written or modified processor will be reviewed under the following standards:
- **Style Consistency**: Indentation, formatting, and naming match the existing codebase.
- **Header Safety**: Ensure only necessary files are included (avoid dragging in large JUCE headers unless necessary).
- **No-Exception Guarantees**: Every processing method has the `noexcept` specifier to prevent stack unwinding overhead.
