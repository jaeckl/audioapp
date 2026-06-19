#include "audioapp/SamplePlayback.hpp"

#include <cmath>
#include <cstdlib>

int main() {
    using namespace audioapp;

    double readPos = 0.0;

    // One-shot forward at start.
    if (!computeSamplerReadPosition(0, 100, 1000, 0, 0, 0.0, 48000.0, 1.0, readPos) ||
        std::abs(readPos - 100.0) > 0.01) {
        return EXIT_FAILURE;
    }

    // One-shot ends after trim window.
    if (computeSamplerReadPosition(0, 100, 200, 0, 0, 1.0, 48000.0, 1.0, readPos)) {
        return EXIT_FAILURE;
    }

    // Loop wraps inside region.
    if (!computeSamplerReadPosition(1, 0, 1000, 200, 400, 0.5, 48000.0, 1.0, readPos)) {
        return EXIT_FAILURE;
    }
    if (readPos < 200.0 || readPos >= 400.0) {
        return EXIT_FAILURE;
    }

    // Reverse moves backward from trim end.
    if (!computeSamplerReadPosition(2, 100, 500, 0, 0, 0.0, 48000.0, 1.0, readPos) ||
        std::abs(readPos - 499.0) > 0.01) {
        return EXIT_FAILURE;
    }

    // Fine tune adds semitone fraction to pitch ratio.
    const double oneSemitone = std::pow(2.0, 1.0 / 12.0);
    if (std::abs(samplerPitchRatio(60, 60, 100.0f) - oneSemitone) > 1.0e-6) {
        return EXIT_FAILURE;
    }
    if (std::abs(samplerPitchRatio(60, 60, 0.0f) - 1.0) > 1.0e-6) {
        return EXIT_FAILURE;
    }
    if (std::abs(samplerPitchRatio(72, 60, 0.0f) - 4.0) > 1.0e-6) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
