# Phase 2 — Command Registry

> **Goal:** Replace `BridgeHost::handleCommand()` 440-line if-else ladder with a command registry where each command is a registered handler. New commands become `addCommand("name", handler)` — no file edits.

## Current State

`BridgeHost::handleCommand()` (`native_bridge/src/BridgeHost.cpp`, lines 27–439) is one function with ~40 `if (method == "...")` branches. Every new command:

1. Adds a new method to `EngineBridge` (Dart)
2. Adds a branch to Kotlin `when(call.method)` — or relies on the catch-all forwarding
3. Adds a new `if` block to `handleCommand()` (C++)
4. Adds a new forwarding method to `EngineHost` (C++)

The Kotlin bridge is a pass-through for all but 5 methods — it simply converts args → JSON → JNI → JSON → map. This pass-through is itself repeated code.

## Design

### A. Command Handler Signature

```cpp
// engine_juce/include/audioapp/commands/CommandHandler.hpp
namespace audioapp::commands {

struct CommandContext {
    EngineHost& engine;
    const juce::var& args;     // parsed from argumentsJson
};

struct CommandResult {
    bool ok = false;
    std::string error;
    juce::var data;            // response payload (e.g. snapshot)

    std::string toJson() const; // serializes to {"ok":true, "snapshot":{...}}
};

using HandlerFn = std::function<CommandResult(const CommandContext& ctx)>;

} // namespace audioapp::commands
```

### B. Command Registry

```cpp
// engine_juce/include/audioapp/commands/CommandRegistry.hpp
namespace audioapp::commands {

class CommandRegistry {
public:
    void registerCommand(std::string name, HandlerFn handler);
    CommandResult execute(std::string_view name, const juce::var& args) const;

    std::vector<std::string_view> knownCommands() const;

private:
    std::unordered_map<std::string, HandlerFn> handlers_;
};

} // namespace audioapp::commands
```

### C. Registration at Startup

Commands register themselves — the pattern is self-contained, no central list:

```cpp
// In EngineHost constructor or static init block:
void EngineHost::registerAllCommands() {
    commandRegistry_.registerCommand("ping", [](const CommandContext& ctx) -> CommandResult {
        return CommandResult::ok("pong");
    });

    commandRegistry_.registerCommand("play", [](const CommandContext& ctx) -> CommandResult {
        ctx.engine.setPlaying(true);
        return CommandResult::ok();
    });

    commandRegistry_.registerCommand("setBpm", [](const CommandContext& ctx) -> CommandResult {
        const double bpm = ctx.args["bpm"];
        if (!ctx.engine.setBpm(static_cast<int>(bpm)))
            return CommandResult::error("invalid_bpm");
        return CommandResult::okWithSnapshot(ctx.engine.getProjectSnapshotJson());
    });

    // ... each command is a self-contained lambda or free function
}
```

For complex commands with heavy logic, extract into a standalone function:

```cpp
// In a separate file (e.g., Command_applySubtractiveSynthPreset.cpp):
static CommandResult handleApplyPreset(const CommandContext& ctx) {
    SubtractivePresetArgs presetArgs;
    if (!parseSubtractivePresetArgs(ctx.args, presetArgs))
        return CommandResult::error("preset_args_invalid");
    if (!ctx.engine.applySubtractiveSynthPreset(...))
        return CommandResult::error("preset_apply_failed");
    return CommandResult::okWithSnapshot(ctx.engine.getProjectSnapshotJson());
}
```

### D. Bridge Simplification

The C++ `BridgeHost::handleCommand()` shrinks to:

```cpp
std::string BridgeHost::handleCommand(const std::string& method,
                                       const std::string& argumentsJson) {
    const auto args = juce::JSON::parse(argumentsJson);
    CommandContext ctx{engine(), args};
    auto result = engine().commandRegistry().execute(method, args);
    return result.toJson();
}
```

The Kotlin bridge keeps only the OS-interactive commands (play/stop with wakelock, SAF pickers). All remaining ~40 commands flow through the generic path without per-method Kotlin branches:

```kotlin
// Kotlin — the generic fallback handles ALL engine commands:
when (call.method) {
    "ping" -> result.success("pong")
    "play" -> { acquirePlaybackWakeLock(); nativePlay(); result.success(null) }
    "stop" -> { releasePlaybackWakeLock(); nativeStop(); result.success(null) }
    "saveProject" -> launchSaveArchivePicker(result)
    "loadProject" -> launchLoadArchivePicker(result)
    "importSample" -> launchImportSamplePicker(result)
    "exportMix" -> launchExportMixPicker(result, lengthBeats)
    else -> {
        // Generic: all engine commands forwarded through single JNI call
        val response = nativeInvoke(call.method, mapToJson(args))
        result.success(jsonToMap(response))
    }
}
```

The Dart `EngineBridge` also simplifies — `_invokeForSnapshot` becomes the single path for every command except the 5 OS-interactive ones:

```dart
// Dart — 40 methods become 3:
Future<ProjectSnapshot> _invokeForSnapshot(String method, [Map<String, dynamic>? args]) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) throw PlatformException(code: 'null_response', ...);
    if (result['ok'] != true) throw PlatformException(code: result['error'], ...);
    return ProjectSnapshot.fromMap(result);
}

// Remaining: play(), stop(), saveProject(), loadProject(), importSample()
// These 5 still need Kotlin-native OS interaction.
// All ~40 engine commands become simple one-liners:
void play() => _invokeOk('play');
Future<ProjectSnapshot> setBpm(int bpm) => _invokeForSnapshot('setBpm', {'bpm': bpm});
// etc. — but now generated from a single template or defined inline.
```

### E. File Organization

Each command handler can live in its own file grouped by domain:

```
engine_juce/src/commands/
├── CMakeLists.txt          # registers all .cpp
├── CommandRegistry.cpp     # registry implementation
├── transport_commands.cpp  # play, stop, setBpm, setPlayheadBeats, setLoop*, setRecordArmed
├── track_commands.cpp      # addTrack, selectTrack, deleteTrack
├── device_commands.cpp     # addDeviceToTrack, removeDeviceFromTrack, setDeviceParameter, setDeviceStringParameter
├── clip_commands.cpp       # createMidiClip, setMidiClipNotes, moveClip, setClipLength, deleteClip, duplicateClip
├── modulator_commands.cpp  # createLfo, removeLfo, updateLfoParam, batchUpdateLfoParams, assignModulation, etc.
├── preview_commands.cpp    # previewSample, previewMidi, previewPreset, stopPreview
├── preset_commands.cpp     # applySubtractiveSynthPreset
├── project_commands.cpp    # createProject, getProjectSnapshot, getDeviceStates, getTransportState
├── midi_commands.cpp       # noteOn, noteOff, allNotesOff, setPitchBend, setModulation, clearCapture, commitCapture
└── automation_commands.cpp # createAutomationClip, assignAutomationTarget, setAutomationPoints
```

## Changes Required

| File | Change |
|------|--------|
| **NEW** `engine_juce/include/audioapp/commands/CommandHandler.hpp` | Handler signature + `CommandResult` struct |
| **NEW** `engine_juce/include/audioapp/commands/CommandRegistry.hpp` | Registry interface |
| **NEW** `engine_juce/src/commands/CommandRegistry.cpp` | Registry impl |
| **NEW** `engine_juce/src/commands/*_commands.cpp` | ~10 files, one per domain |
| **MODIFY** `EngineHost.hpp` | Add `CommandRegistry& commandRegistry()` accessor |
| **MODIFY** `EngineHost.cpp` (or init) | `registerAllCommands()` in constructor |
| **MODIFY** `BridgeHost.cpp` | `handleCommand()` delegates to registry |
| **MODIFY** `BridgeHost.hpp` | No signature changes needed |
| **MODIFY** Kotlin `MainActivity.kt` | Collapse ~40 command branches into single `else` |
| **OPTIONAL** Dart `engine_bridge.dart` | Replace 40 named methods with generic `invoke(method, args)` |

## Test Strategy

1. **Registry unit tests**: Verify command lookup, unknown-command error, param passing
2. **Per-domain tests**: Each command file has its own test coverage (moved from any existing tests)
3. **Bridge integration test**: MethodChannel-like sequence — inject commands via JNI, verify JSON response
4. **Regression**: Every existing bridge test passes with same input/output

## Effort Estimate

| Item | Days |
|------|------|
| `CommandHandler` + `CommandRegistry` skeleton | 0.5 |
| Migrate 1 command (pilot: ping) | 0.25 |
| Write registration in `EngineHost` constructor | 0.5 |
| Split into ~10 domain files | 2 |
| Simplify Kotlin `when` | 0.5 |
| Simplify Dart facade | 0.5 |
| Tests | 2 |
| **Total** | **6.25** |

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Performance: `std::function` overhead per command | Low | Commands are control-thread only; ~1μs overhead is negligible |
| Registering 40 lambdas at startup is expensive | Low | 40 `unordered_map::insert` calls < 1ms total |
| Losing overview of all commands | Medium | `knownCommands()` for introspection; keep a `command_index.md` |
| Complex commands still need refactoring | Low | The registry just dispatches; complex logic still lives in well-named functions |