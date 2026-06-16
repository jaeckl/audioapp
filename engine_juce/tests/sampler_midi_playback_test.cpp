#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Drums");
    if (trackId.empty()) {
        return EXIT_FAILURE;
    }

    host.createMidiClip(trackId, 0.0, 4.0);
    host.setPlaying(true);

    float silent[512] = {};
    host.readMasterMix(silent, 512, 48000.0, 0.0);
    float peakSilent = 0.0f;
    for (const float sample : silent) {
        peakSilent = std::max(peakSilent, std::abs(sample));
    }
    if (peakSilent > 1.0e-4f) {
        return EXIT_FAILURE;
    }

    if (!host.setDeviceStringParameter("dev-1", "sampleId", "sample_kick")) {
        return EXIT_FAILURE;
    }

    float withSample[512] = {};
    host.readMasterMix(withSample, 512, 48000.0, 0.0);
    float peakSample = 0.0f;
    for (const float sample : withSample) {
        peakSample = std::max(peakSample, std::abs(sample));
    }
    if (peakSample <= 1.0e-4f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
