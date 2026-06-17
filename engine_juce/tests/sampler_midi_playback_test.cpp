#include "audioapp/EngineHost.hpp"
#include "audioapp/SamplePlayback.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    using namespace audioapp;

    if (samplerAdsrGain(0.0f, 1.0f, 0.5f, 0.5f, 1.0f, 0.5f) > 0.01f) {
        return EXIT_FAILURE;
    }
    if (std::abs(samplerAdsrGain(0.25f, 1.0f, 0.5f, 0.5f, 1.0f, 0.5f) - 0.5f) > 0.01f) {
        return EXIT_FAILURE;
    }

    EngineHost host;
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

    if (!host.setDeviceParameter("dev-1", "attack", 1.0f)) {
        return EXIT_FAILURE;
    }

    float slowAttack[512] = {};
    host.readMasterMix(slowAttack, 512, 48000.0, 0.0);
    float peakSlow = 0.0f;
    for (const float sample : slowAttack) {
        peakSlow = std::max(peakSlow, std::abs(sample));
    }
    if (peakSlow >= peakSample * 0.95f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
