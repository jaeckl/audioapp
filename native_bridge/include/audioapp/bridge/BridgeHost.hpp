#pragma once

#include <string>

namespace audioapp::bridge {

/// Handles Flutter MethodChannel commands on the platform thread.
class BridgeHost {
public:
    std::string handleCommand(const std::string& method, const std::string& argumentsJson);

    /// Serialize in-memory project for on-disk `project.json` (no file I/O). Used by Android JNI.
    std::string getProjectFileJson();
    /// Parse `project.json` content into the engine; returns bridge JSON response. Used by Android JNI.
    std::string loadProjectFileJson(const std::string& projectJson);

private:
    bool playing_ = false;
};

} // namespace audioapp::bridge
