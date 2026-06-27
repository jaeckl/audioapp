#pragma once

#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "audioapp/commands/CommandHandler.hpp"

namespace audioapp::commands {

/// Registry of named command handlers. Replaces the if-else ladder in
/// BridgeHost::handleCommand().
class CommandRegistry {
public:
    void registerCommand(std::string name, HandlerFn handler);

    CommandResult execute(std::string_view name, const CommandContext& ctx) const;

    std::vector<std::string_view> knownCommands() const;

    bool hasCommand(std::string_view name) const;

private:
    std::unordered_map<std::string, HandlerFn> handlers_;
};

} // namespace audioapp::commands