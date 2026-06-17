#include "audioapp/bridge/BridgeHost.hpp"

#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

namespace audioapp::bridge {

namespace {

EngineHost& engine() {
    static EngineHost instance;
    return instance;
}

} // namespace

std::string BridgeHost::handleCommand(const std::string& method, const std::string& argumentsJson) {
    if (method == "ping") {
        return buildBridgeOkWithMessage(engine().ping());
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
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "getProjectSnapshot") {
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "addTrack") {
        const auto name = jsonGetStringArg(argumentsJson, "name");
        engine().addTrack(name);
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "selectTrack") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        if (!engine().selectTrack(trackId)) {
            return buildBridgeError("track_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "addDeviceToTrack") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        const auto deviceType = jsonGetStringArg(argumentsJson, "deviceType");
        if (engine().addDeviceToTrack(trackId, deviceType).empty()) {
            return buildBridgeError("track_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setDeviceParameter") {
        const auto deviceId = jsonGetStringArg(argumentsJson, "deviceId");
        const auto parameterId = jsonGetStringArg(argumentsJson, "parameterId");
        const auto value = static_cast<float>(jsonGetNumberArg(argumentsJson, "value", 0.0));
        if (!engine().setDeviceParameter(deviceId, parameterId, value)) {
            return buildBridgeError("invalid_parameter");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setMasterGain") {
        const auto value = static_cast<float>(jsonGetNumberArg(argumentsJson, "gain", 1.0));
        if (!engine().setMasterGain(value)) {
            return buildBridgeError("invalid_gain");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setDeviceStringParameter") {
        const auto deviceId = jsonGetStringArg(argumentsJson, "deviceId");
        const auto parameterId = jsonGetStringArg(argumentsJson, "parameterId");
        const auto value = jsonGetStringArg(argumentsJson, "value");
        if (!engine().setDeviceStringParameter(deviceId, parameterId, value)) {
            return buildBridgeError("invalid_parameter");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setPlayheadBeats") {
        const auto beats = jsonGetNumberArg(argumentsJson, "playheadBeats", 0.0);
        engine().setPlayheadBeats(beats);
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "createMidiClip") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        const auto startBeat = jsonGetNumberArg(argumentsJson, "startBeat", 0.0);
        const auto lengthBeats = jsonGetNumberArg(argumentsJson, "lengthBeats", 4.0);
        if (engine().createMidiClip(trackId, startBeat, lengthBeats).empty()) {
            return buildBridgeError("track_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setMidiClipNotes") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        const auto notes = parseMidiNotesFromArgs(argumentsJson);
        if (!engine().setMidiClipNotes(clipId, notes)) {
            return buildBridgeError("clip_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "createSampleClip") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        const auto sampleId = jsonGetStringArg(argumentsJson, "sampleId");
        const auto startBeat = jsonGetNumberArg(argumentsJson, "startBeat", 0.0);
        const auto lengthBeats = jsonGetNumberArg(argumentsJson, "lengthBeats", 0.0);
        if (engine().createSampleClip(trackId, sampleId, startBeat, lengthBeats).empty()) {
            return buildBridgeError("sample_clip_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "moveClip") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        const auto startBeat = jsonGetNumberArg(argumentsJson, "startBeat", 0.0);
        if (!engine().moveClip(clipId, trackId, startBeat)) {
            return buildBridgeError("move_clip_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setBpm") {
        const auto bpm = static_cast<int>(jsonGetNumberArg(argumentsJson, "bpm", 120.0));
        if (!engine().setBpm(bpm)) {
            return buildBridgeError("invalid_bpm");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "deleteTrack") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        if (!engine().deleteTrack(trackId)) {
            return buildBridgeError("delete_track_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "deleteClip") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        if (!engine().deleteClip(clipId)) {
            return buildBridgeError("delete_clip_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setLoopEnabled") {
        const auto enabled = jsonGetBoolArg(argumentsJson, "enabled", true);
        engine().setLoopEnabled(enabled);
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setLoopLengthBeats") {
        const auto length = jsonGetNumberArg(argumentsJson, "lengthBeats", 16.0);
        if (!engine().setLoopLengthBeats(length)) {
            return buildBridgeError("invalid_loop_length");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "previewSample") {
        const auto sampleId = jsonGetStringArg(argumentsJson, "sampleId");
        if (sampleId.empty()) {
            return buildBridgeError("sample_not_found");
        }
        engine().previewSample(sampleId);
        return R"({"ok":true,"previewing":true})";
    }
#ifndef __ANDROID__
    // Desktop bridge hosts: C++ archive I/O (ADR-0006). Android uses Kotlin ProjectArchiveStore.
    if (method == "saveProject") {
        const auto path = jsonGetStringArg(argumentsJson, "path");
        if (path.empty() || !engine().saveProject(path)) {
            return buildBridgeError("save_failed");
        }
        return buildBridgeOkWithPath(path);
    }
    if (method == "loadProject") {
        const auto path = jsonGetStringArg(argumentsJson, "path");
        if (path.empty() || !engine().loadProject(path)) {
            return buildBridgeError("load_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
#endif
    return buildBridgeError("unknown_command");
}

std::string BridgeHost::getProjectFileJson() {
    return engine().getProjectFileJson();
}

std::string BridgeHost::loadProjectFileJson(const std::string& projectJson) {
    if (projectJson.empty() || !engine().loadProjectFileJson(projectJson)) {
        return buildBridgeError("load_failed");
    }
    return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
}

std::string BridgeHost::importWavSample(const std::string& displayName,
                                        const std::vector<uint8_t>& wavBytes) {
    if (wavBytes.empty() || engine().importWavSample(displayName, wavBytes).empty()) {
        return buildBridgeError("import_failed");
    }
    return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
}

std::vector<float> BridgeHost::renderOffline(double lengthBeats, double sampleRate) {
    return engine().renderOffline(lengthBeats, sampleRate);
}

} // namespace audioapp::bridge
