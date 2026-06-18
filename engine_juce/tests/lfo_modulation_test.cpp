#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <cstdlib>
#include <string>

namespace {

audioapp::ProjectFileData readProjectData(const audioapp::EngineHost& host) {
    audioapp::ProjectFileData data;
    if (!audioapp::parseProjectFileJson(host.getProjectFileJson(), data)) {
        return {};
    }
    return data;
}

} // namespace

int main() {
    // --- 1. LFO waveform output values ---
    {
        float v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.25f);
        if (std::abs(v - 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.75f);
        if (std::abs(v + 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.0f);
        if (std::abs(v + 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.5f);
        if (std::abs(v - 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.25f);
        if (std::abs(v) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.0f);
        if (std::abs(v + 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.5f);
        if (std::abs(v) > 0.001f) {
            return EXIT_FAILURE;
        }
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.999f);
        if (v < 0.9f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.25f);
        if (std::abs(v - 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.75f);
        if (std::abs(v + 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }

        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.0f);
        if (std::abs(v - 1.0f) > 0.001f) {
            return EXIT_FAILURE;
        }
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.5f);
        if (std::abs(v) > 0.001f) {
            return EXIT_FAILURE;
        }
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.75f);
        if (std::abs(v + 0.5f) > 0.001f) {
            return EXIT_FAILURE;
        }
    }

    // --- 2. LFO sync beats ---
    {
        if (audioapp::lfoSyncBeats(0) != 0.0) {
            return EXIT_FAILURE;
        }
        if (audioapp::lfoSyncBeats(1) != 1.0) {
            return EXIT_FAILURE;
        }
        if (audioapp::lfoSyncBeats(2) != 0.5) {
            return EXIT_FAILURE;
        }
        if (audioapp::lfoSyncBeats(3) != 0.25) {
            return EXIT_FAILURE;
        }
        if (audioapp::lfoSyncBeats(4) != 0.125) {
            return EXIT_FAILURE;
        }
        if (audioapp::lfoSyncBeats(5) != 0.0625) {
            return EXIT_FAILURE;
        }
    }

    // --- 3. Modulation edge CRUD via EngineHost ---
    {
        audioapp::EngineHost host;
        host.createProject();
        host.addTrack("Test");

        const int lfoId1 = host.createLfo();
        const int lfoId2 = host.createLfo();
        if (lfoId1 < 0 || lfoId2 < 0) {
            return EXIT_FAILURE;
        }

        auto snapshot = readProjectData(host);
        if (snapshot.lfos.size() != 2) {
            return EXIT_FAILURE;
        }

        bool found1 = false;
        bool found2 = false;
        for (const auto& lfo : snapshot.lfos) {
            if (lfo.id == lfoId1) {
                found1 = true;
            }
            if (lfo.id == lfoId2) {
                found2 = true;
            }
        }
        if (!found1 || !found2) {
            return EXIT_FAILURE;
        }

        if (!host.updateLfoParam(lfoId1, "waveform",
                                 static_cast<float>(static_cast<int>(audioapp::LfoWaveform::Square)))) {
            return EXIT_FAILURE;
        }
        if (!host.updateLfoParam(lfoId1, "rate", 2.0f)) {
            return EXIT_FAILURE;
        }

        snapshot = readProjectData(host);
        for (const auto& lfo : snapshot.lfos) {
            if (lfo.id == lfoId1) {
                if (lfo.waveform != static_cast<int>(audioapp::LfoWaveform::Square)) {
                    return EXIT_FAILURE;
                }
                if (std::abs(lfo.rate - 2.0f) > 0.001f) {
                    return EXIT_FAILURE;
                }
            }
        }

        const auto snapDevices = readProjectData(host);
        if (snapDevices.tracks.empty() || snapDevices.tracks[0].devices.empty()) {
            return EXIT_FAILURE;
        }
        const std::string deviceId = snapDevices.tracks[0].devices[0].id;

        if (!host.assignModulation(lfoId1, deviceId, "gain", 0.5f)) {
            return EXIT_FAILURE;
        }
        if (!host.assignModulation(lfoId2, deviceId, "gain", -0.75f)) {
            return EXIT_FAILURE;
        }

        snapshot = readProjectData(host);
        if (snapshot.modEdges.size() != 2) {
            return EXIT_FAILURE;
        }

        int edgeCount = 0;
        for (const auto& edge : snapshot.modEdges) {
            if (edge.lfoId == lfoId1 && edge.deviceId == deviceId && edge.paramId == "gain") {
                if (std::abs(edge.amount - 0.5f) > 0.001f) {
                    return EXIT_FAILURE;
                }
                ++edgeCount;
            }
            if (edge.lfoId == lfoId2 && edge.deviceId == deviceId && edge.paramId == "gain") {
                if (std::abs(edge.amount + 0.75f) > 0.001f) {
                    return EXIT_FAILURE;
                }
                ++edgeCount;
            }
        }
        if (edgeCount != 2) {
            return EXIT_FAILURE;
        }

        if (!host.removeModulation(lfoId1, "gain")) {
            return EXIT_FAILURE;
        }

        snapshot = readProjectData(host);
        if (snapshot.modEdges.size() != 1 || snapshot.modEdges[0].lfoId != lfoId2) {
            return EXIT_FAILURE;
        }

        if (!host.removeLfo(lfoId2)) {
            return EXIT_FAILURE;
        }

        snapshot = readProjectData(host);
        if (snapshot.lfos.size() != 1 || snapshot.modEdges.size() != 0) {
            return EXIT_FAILURE;
        }
        if (snapshot.lfos[0].id != lfoId1) {
            return EXIT_FAILURE;
        }
    }

    // --- 4. LFO/modulation serialization roundtrip ---
    {
        audioapp::EngineHost host;
        host.createProject();
        host.addTrack("Test");

        const int lfoId = host.createLfo();
        if (lfoId < 0) {
            return EXIT_FAILURE;
        }

        host.updateLfoParam(lfoId, "waveform", static_cast<float>(static_cast<int>(audioapp::LfoWaveform::Tri)));
        host.updateLfoParam(lfoId, "rate", 3.5f);

        const auto snapDevices = readProjectData(host);
        if (snapDevices.tracks.empty() || snapDevices.tracks[0].devices.empty()) {
            return EXIT_FAILURE;
        }
        const std::string deviceId = snapDevices.tracks[0].devices[0].id;

        host.assignModulation(lfoId, deviceId, "pan", 0.25f);

        const std::string json = host.getProjectFileJson();
        audioapp::ProjectFileData parsed;
        if (!audioapp::parseProjectFileJson(json, parsed)) {
            return EXIT_FAILURE;
        }

        if (parsed.lfos.size() != 1 || parsed.lfos[0].id != lfoId) {
            return EXIT_FAILURE;
        }
        if (parsed.lfos[0].waveform != static_cast<int>(audioapp::LfoWaveform::Tri)) {
            return EXIT_FAILURE;
        }
        if (std::abs(parsed.lfos[0].rate - 3.5f) > 0.001f) {
            return EXIT_FAILURE;
        }

        if (parsed.modEdges.size() != 1 || parsed.modEdges[0].lfoId != lfoId) {
            return EXIT_FAILURE;
        }
        if (parsed.modEdges[0].paramId != "pan") {
            return EXIT_FAILURE;
        }
        if (std::abs(parsed.modEdges[0].amount - 0.25f) > 0.001f) {
            return EXIT_FAILURE;
        }

        audioapp::EngineHost loaded;
        loaded.createProject();
        if (!loaded.loadProjectFileJson(json)) {
            return EXIT_FAILURE;
        }

        const auto reloadedSnapshot = readProjectData(loaded);
        if (reloadedSnapshot.lfos.size() != 1 || reloadedSnapshot.modEdges.size() != 1) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
