#pragma once

#include <functional>
#include <string>

#include <juce_core/juce_core.h>

namespace audioapp { class EngineHost; }

namespace audioapp::commands {

/// Context passed to every command handler.
struct CommandContext {
    EngineHost& engine;
    const juce::var& args;  // parsed from the incoming arguments JSON
};

/// Result returned by every command handler.
struct CommandResult {
    bool ok = false;
    std::string error;
    juce::var data;  // response payload (e.g. snapshot, transport state)

    /// If non-empty, this raw JSON string is returned verbatim instead of
    /// building a wrapper. Used for commands whose engine method already
    /// returns a complete bridge response (e.g. getTransportState).
    std::string rawJson;

    /// Serialize to JSON response string.
    std::string toJson() const;
};

/// Factory helpers.
inline CommandResult okResult() { return CommandResult{true, {}, {}, {}}; }
inline CommandResult okWithVar(juce::var data) { return CommandResult{true, {}, std::move(data), {}}; }
inline CommandResult errorResult(std::string msg) { return CommandResult{false, std::move(msg), {}, {}}; }
inline CommandResult rawResult(std::string json) { return CommandResult{true, {}, {}, std::move(json)}; }

/// Command handler signature.
using HandlerFn = std::function<CommandResult(const CommandContext& ctx)>;

} // namespace audioapp::commands