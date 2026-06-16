# C++ Guidelines

## Style

- Modern C++ (C++17 minimum)
- Clear naming: `PascalCase` types, `camelCase` functions/members, `snake_case` files
- Prefer explicit over clever

## Realtime path

- No exceptions in `processBlock`
- No heap allocation in audio callback
- Prefer stack buffers and preallocated members
- Avoid `std::shared_ptr` in DSP hot path
- Use stable IDs across layers, not raw cross-thread pointers

## Structure

- `engine_juce/include/` — public engine headers
- `engine_juce/src/` — implementation
- Separate control model from render snapshot
- Devices in dedicated translation units

## JUCE

- Follow [juce_dependency.md](../architecture/juce_dependency.md)
- Minimize JUCE module surface area

## Tests

- GoogleTest or Catch2 (chosen at first test milestone)
- Tests live in `engine_juce/tests/`
- Golden offline render tests for DSP

## Serialization

- Keep JSON parsing off the audio thread
- Version all persisted structures
- Use **`juce::JSON`**, **`juce::var`**, and **`juce::DynamicObject`** for `project.json` read/write (see AGENT.md §2.6)
- Do not add hand-rolled JSON scanners or string concatenation serializers
- Unit tests must round-trip **real** `getProjectFileJson()` output, including pretty-printed whitespace
