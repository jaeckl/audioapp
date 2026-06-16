#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

#include <cmath>
#include <cstdlib>
#include <vector>

int main() {
    audioapp::EngineHost host;
    if (host.ping() != "pong") {
        return EXIT_FAILURE;
    }

    audioapp::TestOscillator osc;
    osc.setFrequency(440.0f);
    osc.setEnabled(true);

    constexpr int numSamples = 512;
    constexpr double sampleRate = 48000.0;
    std::vector<float> buffer(numSamples);
    osc.processBlock(buffer.data(), numSamples, sampleRate);

    float sumSquares = 0.0f;
    for (float s : buffer) {
        sumSquares += s * s;
    }
    const float rms = std::sqrt(sumSquares / static_cast<float>(numSamples));
    if (rms < 0.01f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
