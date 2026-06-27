#include "audioapp/commands/CommandRegistry.hpp"

#include <juce_core/juce_core.h>

namespace audioapp::commands {

void CommandRegistry::registerCommand(std::string name, HandlerFn handler) {
    handlers_[std::move(name)] = std::move(handler);
}

CommandResult CommandRegistry::execute(std::string_view name, const CommandContext& ctx) const {
    auto it = handlers_.find(std::string(name));
    if (it == handlers_.end()) {
        return errorResult("unknown_command: " + std::string(name));
    }
    return it->second(ctx);
}

std::vector<std::string_view> CommandRegistry::knownCommands() const {
    std::vector<std::string_view> result;
    result.reserve(handlers_.size());
    for (const auto& [name, _] : handlers_) {
        result.push_back(name);
    }
    return result;
}

bool CommandRegistry::hasCommand(std::string_view name) const {
    return handlers_.contains(std::string(name));
}

/// === CommandResult serialization ===

std::string CommandResult::toJson() const {
    if (!rawJson.empty()) {
        return rawJson;
    }
    auto* obj = new juce::DynamicObject();
    obj->setProperty("ok", ok);
    if (!error.empty()) {
        obj->setProperty("error", juce::String(error));
    }
    if (deltaData.isObject()) {
        obj->setProperty("delta", deltaData);
    } else if (data.isObject() || data.isArray()) {
        obj->setProperty("snapshot", data);
    }
    return juce::JSON::toString(juce::var(obj), false).toStdString();
}

} // namespace audioapp::commands