#include "audioapp/bridge/BridgeHost.hpp"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cstdlib>
#include <cctype>
#include <sstream>

namespace audioapp::bridge {

namespace {

EngineHost& engine() {
    static EngineHost instance;
    return instance;
}

std::string extractJsonString(const std::string& json, const std::string& key) {
    const std::string needle = "\"" + key + "\":";
    const auto pos = json.find(needle);
    if (pos == std::string::npos) {
        return {};
    }
    size_t i = pos + needle.size();
    while (i < json.size() && std::isspace(static_cast<unsigned char>(json[i]))) {
        ++i;
    }
    if (i >= json.size() || json[i] != '"') {
        return {};
    }
    ++i;
    const auto start = i;
    const auto end = json.find('"', start);
    if (end == std::string::npos) {
        return {};
    }
    return json.substr(start, end - start);
}

std::string escapeJsonString(const std::string& value) {
    std::string out;
    out.reserve(value.size());
    for (char c : value) {
        if (c == '"' || c == '\\') {
            out.push_back('\\');
        }
        out.push_back(c);
    }
    return out;
}

float extractJsonNumber(const std::string& json, const std::string& key) {
    const std::string needle = "\"" + key + "\":";
    const auto pos = json.find(needle);
    if (pos == std::string::npos) {
        return 0.0f;
    }
    size_t i = pos + needle.size();
    while (i < json.size() && std::isspace(static_cast<unsigned char>(json[i]))) {
        ++i;
    }
    return std::strtof(json.c_str() + i, nullptr);
}

std::string okWithSnapshot() {
  return std::string(R"({"ok":true,"snapshot":)") + engine().getProjectSnapshotJson() + "}";
}

} // namespace

std::string BridgeHost::handleCommand(const std::string& method, const std::string& argumentsJson) {
    if (method == "ping") {
        return R"({"ok":true,"message":")" + engine().ping() + R"("})";
    }
    if (method == "play") {
        playing_ = true;
        engine().setPlaying(true);
        return R"({"ok":true,"playing":true})";
    }
    if (method == "stop") {
        playing_ = false;
        engine().setPlaying(false);
        return R"({"ok":true,"playing":false})";
    }
    if (method == "createProject") {
        engine().createProject();
        return okWithSnapshot();
    }
    if (method == "getProjectSnapshot") {
        return okWithSnapshot();
    }
    if (method == "addTrack") {
        const auto name = extractJsonString(argumentsJson, "name");
        engine().addTrack(name);
        return okWithSnapshot();
    }
    if (method == "selectTrack") {
        const auto trackId = extractJsonString(argumentsJson, "trackId");
        if (!engine().selectTrack(trackId)) {
            return R"({"ok":false,"error":"track_not_found"})";
        }
        return okWithSnapshot();
    }
    if (method == "addDeviceToTrack") {
        const auto trackId = extractJsonString(argumentsJson, "trackId");
        const auto deviceType = extractJsonString(argumentsJson, "deviceType");
        if (engine().addDeviceToTrack(trackId, deviceType).empty()) {
            return R"({"ok":false,"error":"track_not_found"})";
        }
        return okWithSnapshot();
    }
    if (method == "setDeviceParameter") {
        const auto deviceId = extractJsonString(argumentsJson, "deviceId");
        const auto parameterId = extractJsonString(argumentsJson, "parameterId");
        const auto value = extractJsonNumber(argumentsJson, "value");
        if (!engine().setDeviceParameter(deviceId, parameterId, value)) {
            return R"({"ok":false,"error":"invalid_parameter"})";
        }
        return okWithSnapshot();
    }
    if (method == "createMidiClip") {
        const auto trackId = extractJsonString(argumentsJson, "trackId");
        const auto startBeat = extractJsonNumber(argumentsJson, "startBeat");
        const auto lengthBeats = extractJsonNumber(argumentsJson, "lengthBeats");
        if (engine().createMidiClip(trackId, startBeat, lengthBeats).empty()) {
            return R"({"ok":false,"error":"track_not_found"})";
        }
        return okWithSnapshot();
    }
    if (method == "setMidiClipNotes") {
        const auto clipId = extractJsonString(argumentsJson, "clipId");
        const auto notes = parseMidiNotesFromArgs(argumentsJson);
        if (!engine().setMidiClipNotes(clipId, notes)) {
            return R"({"ok":false,"error":"clip_not_found"})";
        }
        return okWithSnapshot();
    }
#ifndef __ANDROID__
    // Desktop bridge hosts: C++ archive I/O (ADR-0006). Android uses Kotlin ProjectArchiveStore.
    if (method == "saveProject") {
        const auto path = extractJsonString(argumentsJson, "path");
        if (path.empty() || !engine().saveProject(path)) {
            return R"({"ok":false,"error":"save_failed"})";
        }
        return R"({"ok":true,"path":")" + escapeJsonString(path) + "\"}";
    }
    if (method == "loadProject") {
        const auto path = extractJsonString(argumentsJson, "path");
        if (path.empty() || !engine().loadProject(path)) {
            return R"({"ok":false,"error":"load_failed"})";
        }
        return okWithSnapshot();
    }
#endif
    return R"({"ok":false,"error":"unknown_command"})";
}

std::string BridgeHost::getProjectFileJson() {
    return engine().getProjectFileJson();
}

std::string BridgeHost::loadProjectFileJson(const std::string& projectJson) {
    if (projectJson.empty() || !engine().loadProjectFileJson(projectJson)) {
        return R"({"ok":false,"error":"load_failed"})";
    }
    return okWithSnapshot();
}

} // namespace audioapp::bridge
