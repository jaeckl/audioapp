#include "audioapp/EngineHost.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    audioapp::EngineHost host;
    host.createProject();
    host.addTrack("A");
    host.addTrack("B");
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
