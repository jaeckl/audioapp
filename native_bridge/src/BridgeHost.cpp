#include "audioapp/bridge/BridgeHost.hpp"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <juce_core/juce_core.h>

namespace audioapp::bridge {

namespace {

EngineHost& engine() {
    static EngineHost instance;
    return instance;
}

std::string buildBridgeError(const std::string& errorCode) {
    return R"({"ok":false,"error":")" + errorCode + R"("})";
}

} // namespace

std::string BridgeHost::handleCommand(const std::string& method, const std::string& argumentsJson) {
    // Play, stop, saveProject, loadProject, importSample, exportMix are handled
    // on the Kotlin side (OS-interactive). All other commands route through the
    // command registry. Adding a new command requires zero bridge changes.
    auto args = juce::JSON::parse(juce::String::fromUTF8(argumentsJson.c_str()));
    auto result = engine().commandRegistry().execute(method, {engine(), args});
    return result.toJson();
}

std::string BridgeHost::getProjectFileJson() {
    return engine().getProjectFileJson();
}

std::string BridgeHost::loadProjectFileJson(const std::string& projectJson) {
    if (projectJson.empty() || !engine().loadProjectFileJson(projectJson)) {
        return buildBridgeError("load_failed");
    }
    auto args = juce::JSON::parse(juce::String("{}"));
    auto result = engine().commandRegistry().execute("getProjectSnapshot", {engine(), args});
    return result.toJson();
}

std::string BridgeHost::importWavSample(const std::string& displayName,
                                        const std::vector<uint8_t>& wavBytes) {
    if (wavBytes.empty() || engine().importWavSample(displayName, wavBytes).empty()) {
        return buildBridgeError("import_failed");
    }
    auto args = juce::JSON::parse(juce::String("{}"));
    auto result = engine().commandRegistry().execute("getProjectSnapshot", {engine(), args});
    return result.toJson();
}

std::vector<float> BridgeHost::renderOffline(double lengthBeats, double sampleRate) {
    return engine().renderOffline(lengthBeats, sampleRate);
}

} // namespace audioapp::bridge