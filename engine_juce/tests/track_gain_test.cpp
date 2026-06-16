#include "audioapp/ProjectEngine.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::ProjectEngine project;
    project.createProject();
    const std::string trackId = project.addTrack("A");
    if (trackId.empty()) {
        return EXIT_FAILURE;
    }

    const auto snap = project.snapshot();
    if (snap.tracks.size() != 1 || snap.tracks[0].devices.size() < 2) {
        return EXIT_FAILURE;
    }

    const auto& gainDevice = snap.tracks[0].devices.back();
    if (gainDevice.type != "track_gain") {
        return EXIT_FAILURE;
    }

    if (!project.setDeviceParameter(gainDevice.id, "gain", 0.5f)) {
        return EXIT_FAILURE;
    }

    project.setPlaying(true);
    float full[256] = {};
    float half[256] = {};
    project.readMasterMix(full, 256, 48000.0, 0.0);

    if (!project.setDeviceParameter(gainDevice.id, "gain", 0.25f)) {
        return EXIT_FAILURE;
    }
    project.readMasterMix(half, 256, 48000.0, 0.0);

    float peakFull = 0.0f;
    float peakHalf = 0.0f;
    for (int i = 0; i < 256; ++i) {
        peakFull = std::max(peakFull, std::abs(full[i]));
        peakHalf = std::max(peakHalf, std::abs(half[i]));
    }

    if (peakFull <= 0.0f || peakHalf <= 0.0f) {
        return EXIT_FAILURE;
    }

    if (peakHalf >= peakFull * 0.9f) {
        return EXIT_FAILURE;
    }

    if (!project.setMasterGain(0.5f)) {
        return EXIT_FAILURE;
    }

    float masterHalf[256] = {};
    project.readMasterMix(masterHalf, 256, 48000.0, 0.0);
    float peakMasterHalf = 0.0f;
    for (const float sample : masterHalf) {
        peakMasterHalf = std::max(peakMasterHalf, std::abs(sample));
    }

    if (peakMasterHalf >= peakHalf * 0.95f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
