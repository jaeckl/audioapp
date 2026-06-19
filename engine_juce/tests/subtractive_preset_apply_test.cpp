#include "audioapp/EngineHost.hpp"
#include "audioapp/devices/DeviceTypeIds.hpp"

#include <cstdio>
#include <string>
#include <utility>
#include <vector>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const auto trackId = host.addTrack("Test");
    const auto deviceId =
        host.addDeviceToTrack(trackId, audioapp::device_types::kSubtractiveSynth);

    std::vector<std::pair<std::string, float>> params{
        {"gain", 0.8f},
        {"filterCutoff", 0.4f},
        {"attack", 0.1f},
        {"decay", 0.2f},
        {"sustain", 0.7f},
        {"release", 0.3f},
        {"filterQ", 0.2f},
        {"filterMode", 0.0f},
        {"filterEnvAmount", 0.5f},
        {"filterAttack", 0.05f},
        {"filterDecay", 0.35f},
        {"filterSustain", 0.4f},
        {"filterRelease", 0.45f},
        {"filterKeyTrack", 0.35f},
        {"filterDrive", 0.0f},
        {"filterFm", 0.0f},
        {"filterShaper", 0.0f},
        {"filterShaperMode", 1.0f},
        {"osc1Shape", 0.5f},
        {"osc2Shape", 0.5f},
        {"osc1Octave", 0.5f},
        {"osc2Octave", 0.5f},
        {"osc1Semi", 0.0f},
        {"osc2Semi", 0.0f},
        {"osc1Detune", 0.5f},
        {"osc2Detune", 0.5f},
        {"oscMix", 0.37f},
        {"oscMixMode", 0.0f},
        {"osc1Sync", 0.0f},
        {"osc2Sync", 0.0f},
        {"noiseLevel", 0.0f},
        {"unisonVoices", 0.0f},
        {"unisonDetune", 0.5f},
        {"glideMs", 0.0f},
        {"preHpCutoff", 0.0f},
        {"preHpRes", 0.2f},
        {"preDrive", 0.0f},
        {"mixFeedback", 0.0f},
        {"globalPitch", 0.5f},
        {"synthMono", 0.0f},
        {"synthLegato", 0.0f},
        {"velocitySensitivity", 1.0f},
    };

    std::vector<audioapp::ProjectEngine::SubtractivePresetLfoSpec> lfos;
    lfos.push_back({0, 1.0f, 3, 0.0f, 0});

    std::vector<audioapp::ProjectEngine::SubtractivePresetModSpec> mods;
    mods.push_back({0, "filterCutoff", 0.3f});

    if (!host.applySubtractiveSynthPreset(deviceId, params, lfos, mods)) {
        std::fprintf(stderr, "applySubtractiveSynthPreset failed\n");
        return 1;
    }

    const auto snapshotJson = host.getProjectSnapshotJson();
    if (snapshotJson.find(deviceId) == std::string::npos ||
        snapshotJson.find("\"paramId\": \"filterCutoff\"") == std::string::npos) {
        std::fprintf(stderr, "expected mod edge on filterCutoff in snapshot\n");
        return 1;
    }

    std::printf("subtractive_preset_apply_test: ok\n");
    return 0;
}
