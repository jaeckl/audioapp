#include "audioapp/EngineHost.hpp"
#include "audioapp/ProjectJson.hpp"

#include <cmath>
#include <cstdlib>
#include <string>

int main() {
    // --- 1. LFO waveform output values ---
    {
        // Sine: phase 0.25 -> sin(pi/2) = 1.0
        float v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.25f);
        if (std::abs(v - 1.0f) > 0.001f) return EXIT_FAILURE;

        // Sine: phase 0.75 -> sin(3*pi/2) = -1.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Sine, 0.75f);
        if (std::abs(v + 1.0f) > 0.001f) return EXIT_FAILURE;

        // Tri: phase 0.0 -> 1.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.0f);
        if (std::abs(v - 1.0f) > 0.001f) return EXIT_FAILURE;

        // Tri: phase 0.5 -> -1.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.5f);
        if (std::abs(v + 1.0f) > 0.001f) return EXIT_FAILURE;

        // Tri: phase 0.25 -> 0.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Tri, 0.25f);
        if (std::abs(v) > 0.001f) return EXIT_FAILURE;

        // Saw: phase 0.0 -> -1.0, phase 0.5 -> 0.0, phase ~1.0 -> ~1.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.0f);
        if (std::abs(v + 1.0f) > 0.001f) return EXIT_FAILURE;
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.5f);
        if (std::abs(v) > 0.001f) return EXIT_FAILURE;
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Saw, 0.999f);
        if (v < 0.9f) return EXIT_FAILURE;

        // Square: phase 0.25 -> 1.0, phase 0.75 -> -1.0
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.25f);
        if (std::abs(v - 1.0f) > 0.001f) return EXIT_FAILURE;
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Square, 0.75f);
        if (std::abs(v + 1.0f) > 0.001f) return EXIT_FAILURE;

        // Ramp: phase 0.0 -> 1.0, phase 0.5 -> 0.0, phase 0.75 -> -0.5
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.0f);
        if (std::abs(v - 1.0f) > 0.001f) return EXIT_FAILURE;
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.5f);
        if (std::abs(v) > 0.001f) return EXIT_FAILURE;
        v = audioapp::lfoEvaluate(audioapp::LfoWaveform::Ramp, 0.75f);
        if (std::abs(v + 0.5f) > 0.001f) return EXIT_FAILURE;
    }

    // --- 2. LFO sync beats ---
    {
        if (audioapp::lfoSyncBeats(0) != 0.0)    return EXIT_FAILURE; // free/Hz mode
        if (audioapp::lfoSyncBeats(1) != 1.0)    return EXIT_FAILURE; // 1/1
        if (audioapp::lfoSyncBeats(2) != 0.5)    return EXIT_FAILURE; // 1/2
        if (audioapp::lfoSyncBeats(3) != 0.25)   return EXIT_FAILURE; // 1/4
        if (audioapp::lfoSyncBeats(4) != 0.125)  return EXIT_FAILURE; // 1/8
        if (audioapp::lfoSyncBeats(5) != 0.0625) return EXIT_FAILURE; // 1/16
    }

    // --- 3. Modulation edge CRUD via EngineHost ---
    {
        audioapp::EngineHost host;
        host.createProject();

        // Create LFO 1
        const int lfoId1 = host.createLfo();
        if (lfoId1 < 0) return EXIT_FAILURE;

        // Create LFO 2
        const int lfoId2 = host.createLfo();
        if (lfoId2 < 0) return EXIT_FAILURE;

        // Get snapshot and verify lfos exist
        auto snapshot = host.getProjectSnapshot();
        if (snapshot.lfos.size() != 2) return EXIT_FAILURE;

        // Verify LFO IDs
        bool found1 = false, found2 = false;
        for (const auto& lfo : snapshot.lfos) {
            if (lfo.id == lfoId1) found1 = true;
            if (lfo.id == lfoId2) found2 = true;
        }
        if (!found1 || !found2) return EXIT_FAILURE;

        // Update LFO 1 parameters
        if (!host.updateLfoParam(lfoId1, "waveform", static_cast<double>(static_cast<int>(audioapp::LfoWaveform::Square)))) {
            return EXIT_FAILURE;
        }
        if (!host.updateLfoParam(lfoId1, "rate", 2.0)) {
            return EXIT_FAILURE;
        }

        snapshot = host.getProjectSnapshot();
        for (const auto& lfo : snapshot.lfos) {
            if (lfo.id == lfoId1) {
                if (lfo.waveform != static_cast<int>(audioapp::LfoWaveform::Square)) return EXIT_FAILURE;
                if (std::abs(lfo.rate - 2.0f) > 0.001f) return EXIT_FAILURE;
            }
        }

        // Assign modulation edge (need a track with a device to target)
        const auto snapDevices = host.getProjectSnapshot();
        std::string deviceId;
        if (!snapDevices.tracks.empty() && !snapDevices.tracks[0].devices.empty()) {
            deviceId = snapDevices.tracks[0].devices[0].id;
        }
        if (deviceId.empty()) return EXIT_FAILURE;

        if (!host.assignModulation(lfoId1, deviceId, "gain", 0.5f)) {
            return EXIT_FAILURE;
        }
        if (!host.assignModulation(lfoId2, deviceId, "gain", -0.75f)) {
            return EXIT_FAILURE;
        }

        // Verify edges in snapshot
        snapshot = host.getProjectSnapshot();
        if (snapshot.modEdges.size() != 2) return EXIT_FAILURE;

        int edgeCount = 0;
        for (const auto& edge : snapshot.modEdges) {
            if (edge.lfoId == lfoId1 && edge.deviceId == deviceId && edge.paramId == "gain") {
                if (std::abs(edge.amount - 0.5f) > 0.001f) return EXIT_FAILURE;
                ++edgeCount;
            }
            if (edge.lfoId == lfoId2 && edge.deviceId == deviceId && edge.paramId == "gain") {
                if (std::abs(edge.amount + 0.75f) > 0.001f) return EXIT_FAILURE;
                ++edgeCount;
            }
        }
        if (edgeCount != 2) return EXIT_FAILURE;

        // Remove one modulation edge
        if (!host.removeModulation(lfoId1, "gain")) {
            return EXIT_FAILURE;
        }

        snapshot = host.getProjectSnapshot();
        if (snapshot.modEdges.size() != 1) return EXIT_FAILURE;
        if (snapshot.modEdges[0].lfoId != lfoId2) return EXIT_FAILURE;

        // Remove LFO 2 (should also remove its edges)
        if (!host.removeLfo(lfoId2)) return EXIT_FAILURE;

        snapshot = host.getProjectSnapshot();
        if (snapshot.lfos.size() != 1) return EXIT_FAILURE;
        // After removing LFO 2, its edge should be gone as well
        if (snapshot.modEdges.size() != 0) return EXIT_FAILURE;

        // Verify only LFO 1 remains
        if (snapshot.lfos[0].id != lfoId1) return EXIT_FAILURE;
    }

    // --- 4. LFO/modulation serialization roundtrip ---
    {
        audioapp::EngineHost host;
        host.createProject();

        const int lfoId = host.createLfo();
        if (lfoId < 0) return EXIT_FAILURE;

        host.updateLfoParam(lfoId, "waveform", static_cast<double>(static_cast<int>(audioapp::LfoWaveform::Tri)));
        host.updateLfoParam(lfoId, "rate", 3.5);

        const auto snapDevices = host.getProjectSnapshot();
        std::string deviceId;
        if (!snapDevices.tracks.empty() && !snapDevices.tracks[0].devices.empty()) {
            deviceId = snapDevices.tracks[0].devices[0].id;
        }
        if (deviceId.empty()) return EXIT_FAILURE;

        host.assignModulation(lfoId, deviceId, "pan", 0.25f);

        // Serialize to project file JSON and back
        const std::string json = host.getProjectFileJson();
        audioapp::ProjectFileData parsed;
        if (!audioapp::parseProjectFileJson(json, parsed)) return EXIT_FAILURE;

        if (parsed.lfos.size() != 1) return EXIT_FAILURE;
        if (parsed.lfos[0].id != lfoId) return EXIT_FAILURE;
        if (parsed.lfos[0].waveform != static_cast<int>(audioapp::LfoWaveform::Tri)) return EXIT_FAILURE;
        if (std::abs(parsed.lfos[0].rate - 3.5f) > 0.001f) return EXIT_FAILURE;

        if (parsed.modEdges.size() != 1) return EXIT_FAILURE;
        if (parsed.modEdges[0].lfoId != lfoId) return EXIT_FAILURE;
        if (parsed.modEdges[0].paramId != "pan") return EXIT_FAILURE;
        if (std::abs(parsed.modEdges[0].amount - 0.25f) > 0.001f) return EXIT_FAILURE;

        // Reload into new host
        audioapp::EngineHost loaded;
        loaded.createProject();
        if (!loaded.loadProjectFileJson(json)) return EXIT_FAILURE;

        const auto reloadedSnapshot = loaded.getProjectSnapshot();
        if (reloadedSnapshot.lfos.size() != 1) return EXIT_FAILURE;
        if (reloadedSnapshot.modEdges.size() != 1) return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
