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
    if (method == "getTransportState") {
        return engine().getTransportStateJson();
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
        const auto insertIndex = static_cast<int>(jsonGetNumberArg(argumentsJson, "insertIndex", -1.0));
        if (engine().addDeviceToTrack(trackId, deviceType, insertIndex).empty()) {
            return buildBridgeError("track_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "removeDeviceFromTrack") {
        const auto deviceId = jsonGetStringArg(argumentsJson, "deviceId");
        if (!engine().removeDeviceFromTrack(deviceId)) {
            return buildBridgeError("device_not_removable");
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
    if (method == "createAutomationClip") {
        const auto trackId = jsonGetStringArg(argumentsJson, "trackId");
        const auto startBeat = jsonGetNumberArg(argumentsJson, "startBeat", 0.0);
        const auto lengthBeats = jsonGetNumberArg(argumentsJson, "lengthBeats", 4.0);
        if (engine().createAutomationClip(trackId, startBeat, lengthBeats).empty()) {
            return buildBridgeError("automation_clip_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "assignAutomationTarget") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        const auto deviceId = jsonGetStringArg(argumentsJson, "deviceId");
        const auto paramId = jsonGetStringArg(argumentsJson, "paramId");
        if (!engine().assignAutomationTarget(clipId, deviceId, paramId)) {
            return buildBridgeError("assign_automation_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setAutomationPoints") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        const auto points = parseAutomationPointsFromArgs(argumentsJson);
        if (!engine().setAutomationPoints(clipId, points)) {
            return buildBridgeError("automation_points_failed");
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
    if (method == "setClipLength") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        const auto lengthBeats = jsonGetNumberArg(argumentsJson, "lengthBeats", 4.0);
        if (!engine().setClipLength(clipId, lengthBeats)) {
            return buildBridgeError("clip_not_found");
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
    if (method == "duplicateClip") {
        const auto clipId = jsonGetStringArg(argumentsJson, "clipId");
        if (!engine().duplicateClip(clipId)) {
            return buildBridgeError("duplicate_clip_failed");
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
    if (method == "setLoopRegion") {
        const auto startBeat = jsonGetNumberArg(argumentsJson, "startBeat", 0.0);
        const auto endBeat = jsonGetNumberArg(argumentsJson, "endBeat", 16.0);
        if (!engine().setLoopRegion(startBeat, endBeat)) {
            return buildBridgeError("invalid_loop_region");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "setRecordArmed") {
        const auto armed = jsonGetBoolArg(argumentsJson, "armed", false);
        engine().setRecordArmed(armed);
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "noteOn") {
        const auto pitch = static_cast<int>(jsonGetNumberArg(argumentsJson, "pitch", 60.0));
        const auto velocity = static_cast<float>(jsonGetNumberArg(argumentsJson, "velocity", 100.0));
        if (!engine().noteOn(pitch, velocity)) {
            return buildBridgeError("note_on_failed");
        }
        return R"({"ok":true})";
    }
    if (method == "noteOff") {
        const auto pitch = static_cast<int>(jsonGetNumberArg(argumentsJson, "pitch", 60.0));
        engine().noteOff(pitch);
        return R"({"ok":true})";
    }
    if (method == "allNotesOff") {
        engine().allNotesOff();
        return R"({"ok":true})";
    }
    if (method == "setPitchBend") {
        const auto bend = jsonGetNumberArg(argumentsJson, "bend", 0.0);
        engine().setPitchBend(static_cast<float>(bend));
        return R"({"ok":true})";
    }
    if (method == "setModulation") {
        const auto mod = jsonGetNumberArg(argumentsJson, "mod", 0.0);
        engine().setModulation(static_cast<float>(mod));
        return R"({"ok":true})";
    }
    if (method == "clearCapture") {
        engine().clearCapture();
        return R"({"ok":true})";
    }
    if (method == "commitCapture") {
        if (!engine().commitCapture()) {
            return buildBridgeError("capture_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "createLfo") {
        const auto modulatorType =
            static_cast<int>(jsonGetNumberArg(argumentsJson, "modulatorType", 0.0));
        engine().createLfo(modulatorType);
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "removeLfo") {
        const auto lfoId = static_cast<int>(jsonGetNumberArg(argumentsJson, "lfoId", 0.0));
        if (!engine().removeLfo(lfoId)) {
            return buildBridgeError("lfo_not_found");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "updateLfoParam") {
        const auto lfoId = static_cast<int>(jsonGetNumberArg(argumentsJson, "lfoId", 0.0));
        const auto param = jsonGetStringArg(argumentsJson, "param");
        const auto value = static_cast<float>(jsonGetNumberArg(argumentsJson, "value", 0.0));
        if (!engine().updateLfoParam(lfoId, param, value)) {
            return buildBridgeError("lfo_param_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "assignModulation") {
        const auto lfoId = static_cast<int>(jsonGetNumberArg(argumentsJson, "lfoId", 0.0));
        const auto deviceId = jsonGetStringArg(argumentsJson, "deviceId");
        const auto paramId = jsonGetStringArg(argumentsJson, "paramId");
        const auto amount = static_cast<float>(jsonGetNumberArg(argumentsJson, "amount", 0.0));
        if (!engine().assignModulation(lfoId, deviceId, paramId, amount)) {
            return buildBridgeError("modulation_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "removeModulation") {
        const auto lfoId = static_cast<int>(jsonGetNumberArg(argumentsJson, "lfoId", 0.0));
        const auto paramId = jsonGetStringArg(argumentsJson, "paramId");
        if (!engine().removeModulation(lfoId, paramId)) {
            return buildBridgeError("modulation_remove_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "applySubtractiveSynthPreset") {
        SubtractivePresetArgs presetArgs;
        if (!parseSubtractivePresetArgs(argumentsJson, presetArgs)) {
            return buildBridgeError("preset_args_invalid");
        }
        if (!engine().applySubtractiveSynthPreset(
                presetArgs.deviceId, presetArgs.params, presetArgs.lfos, presetArgs.mods)) {
            return buildBridgeError("preset_apply_failed");
        }
        return buildBridgeOkWithSnapshot(engine().getProjectSnapshotJson());
    }
    if (method == "enterPlayMode") {
        engine().enterPlayMode();
        return R"({"ok":true})";
    }
    if (method == "previewSample") {
        const auto sampleId = jsonGetStringArg(argumentsJson, "sampleId");
        if (sampleId.empty()) {
            return buildBridgeError("sample_not_found");
        }
        engine().previewSample(sampleId);
        return R"({"ok":true,"previewing":true})";
    }
    if (method == "previewMidi") {
        const auto notes = parseMidiNotesFromArgs(argumentsJson);
        const auto lengthBeats = jsonGetNumberArg(argumentsJson, "lengthBeats", 4.0);
        const auto bpm = static_cast<int>(jsonGetNumberArg(argumentsJson, "bpm", 120.0));
        if (notes.empty()) {
            return R"({"ok":true,"previewing":false})";
        }
        engine().previewMidi(notes, lengthBeats, bpm);
        return R"({"ok":true,"previewing":true})";
    }
    if (method == "stopPreview") {
        engine().stopPreview();
        return R"({"ok":true})";
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
    if (method == "getDeviceStates") {
        // Parse the deviceIds array from the arguments JSON
        const auto root = juce::JSON::parse(juce::String::fromUTF8(argumentsJson.c_str()));
        const auto* rootObj = root.getDynamicObject();
        if (rootObj == nullptr) return buildBridgeError("invalid_args");
        const auto& idsVar = rootObj->getProperty("deviceIds");
        const auto* idsArray = idsVar.getArray();
        if (idsArray == nullptr) return buildBridgeError("invalid_deviceIds");
        std::vector<std::string> deviceIds;
        for (const auto& idVar : *idsArray) {
            deviceIds.push_back(idVar.toString().toStdString());
        }
        return engine().getDeviceStatesJson(deviceIds);
    }
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
