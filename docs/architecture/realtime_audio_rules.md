# Realtime Audio Rules

These rules apply to all code running on the JUCE audio callback thread and any code it calls synchronously during `processBlock`.

## Forbidden on the audio thread

- Heap allocation (`new`, `malloc`, `std::vector::push_back`, `std::string` growth, etc.)
- Locks, mutex waits, condition variables
- File I/O
- Logging (`std::cout`, Android log, JUCE `Logger`)
- Flutter/Dart or platform channel calls
- Blocking system calls
- Waiting on futures/promises
- Unbounded graph mutation
- Dynamic memory growth
- String or JSON parsing
- UI access

## Required patterns

- Preallocated audio buffers owned for the session or graph lifetime
- Command queues: UI/control thread enqueues; audio thread dequeues at block boundaries
- Immutable graph snapshots or double-buffered render graphs
- Parameter values as atomic floats or lock-free queues
- MIDI event buffers preallocated per block
- Deterministic, bounded processing order

## Control vs render separation

| Concern | Thread | Examples |
|---------|--------|----------|
| User edits, save/load | UI / worker | add track, load project |
| Command validation | Bridge / engine control | parse command, build new graph |
| Graph swap | Audio thread entry or dedicated sync point | apply pending snapshot |
| DSP | Audio thread | oscillator, sampler, effects |

## Bridge implications

- MethodChannel is **never** called from the audio thread
- State updates to Flutter are throttled on a non-audio thread
- Playhead updates: coalesce to ≤ 30 Hz unless testing requires more

## Testing

- Unit tests for graph logic off the audio thread
- Offline render tests for deterministic DSP output
- Static review checklist for new device `processBlock` implementations

## Violations

Code that knowingly violates these rules must update [performance budgets](../testing/performance_budgets.md) with justification.
