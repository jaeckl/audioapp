#pragma once

#include <string>
#include <vector>

namespace audioapp::bridge {

/// Handles Flutter MethodChannel commands on the platform thread.
class BridgeHost {
public:
    std::string handleCommand(const std::string& method, const std::string& argumentsJson);

    /// Serialize in-memory project for on-disk `project.json` (no file I/O). Used by Android JNI.
    std::string getProjectFileJson();
    /// Parse `project.json` content into the engine; returns bridge JSON response. Used by Android JNI.
    std::string loadProjectFileJson(const std::string& projectJson);
    std::string importWavSample(const std::string& displayName, const std::vector<uint8_t>& wavBytes);
    std::vector<float> renderOffline(double lengthBeats, double sampleRate);

private:
    bool playing_ = false;
};

} // namespace audioapp::bridge
