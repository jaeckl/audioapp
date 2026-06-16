# Milestone 05 — Save & Load

**Product intent:** The user can save and open projects like any serious mobile app — system dialogs, one zip file, full round-trip after force-stop. No engine-only milestone; no “add dialog later” amendments.

| Story | Summary |
|-------|---------|
| [US-05-01](../../tickets/milestone-05/US-05-01-save-project.md) | Save via system dialog → `.audioapp.zip` |
| [US-05-02](../../tickets/milestone-05/US-05-02-load-project.md) | Load via system dialog → restore arrangement |

## PO sign-off demo

1. Add track + MIDI clip → **Save** (`project.audioapp.zip`)
2. Force-stop app → relaunch → **Load** same file
3. Arrangement, device strip, and Play match step 1

## Engineering notes

- C++: `juce::JSON` for `project.json` (AGENT.md §2.6)
- Android: SAF `CreateDocument` / `OpenDocument` in Kotlin (ADR-0006)
- Tests must parse real serialized output, not fixture strings only

[roadmap](roadmap.md)
