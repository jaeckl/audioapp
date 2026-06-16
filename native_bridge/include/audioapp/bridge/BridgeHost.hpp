#pragma once

#include <string>

namespace audioapp::bridge {

/// Handles Flutter MethodChannel commands on the platform thread.
class BridgeHost {
public:
    std::string handleCommand(const std::string& method, const std::string& argumentsJson);

private:
    bool playing_ = false;
};

} // namespace audioapp::bridge
