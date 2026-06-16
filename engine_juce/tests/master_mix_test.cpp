#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackA = host.addTrack("A");
    const std::string trackB = host.addTrack("B");
    if (trackA.empty() || trackB.empty()) {
        return EXIT_FAILURE;
    }

    if (host.createSampleClip(trackA, "sample_kick", 0.0, 0.0).empty()) {
        return EXIT_FAILURE;
    }
    if (host.createSampleClip(trackB, "sample_snare", 0.0, 0.0).empty()) {
        return EXIT_FAILURE;
    }

    host.setPlaying(true);

    float buffer[256] = {};
    host.readMasterMix(buffer, 256, 48000.0, 0.0);

    float peak = 0.0f;
    for (const float sample : buffer) {
        peak = std::max(peak, std::abs(sample));
    }

    if (peak <= 0.0f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
