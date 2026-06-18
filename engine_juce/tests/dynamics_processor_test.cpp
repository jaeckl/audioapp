#include "audioapp/DynamicsProcessor.hpp"

#include <cmath>
#include <cstdlib>
#include <cstring>

namespace {

float peakAbs(const float* left, const float* right, int count) {
    float peak = 0.0f;
    for (int i = 0; i < count; ++i) {
        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
    }
    return peak;
}

} // namespace

int main() {
    constexpr int kFrames = 2048;
    constexpr double kSampleRate = 48000.0;

    float left[kFrames];
    float right[kFrames];
    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));

    for (int i = 400; i < 800; ++i) {
        left[i] = 0.85f;
        right[i] = 0.85f;
    }

    audioapp::GateParams gateParams;
    gateParams.gateThreshold = 0.50f;
    gateParams.gateRange = 0.0f;
    audioapp::DynamicsRuntime gateRuntime{};
    audioapp::processGateStereoBlock(left, right, kFrames, kSampleRate, gateParams, gateRuntime);

    if (peakAbs(left, right, 200) > 0.01f) {
        return EXIT_FAILURE;
    }
    if (peakAbs(left + 500, right + 500, 300) < 0.05f) {
        return EXIT_FAILURE;
    }

    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));
    for (int i = 0; i < kFrames; ++i) {
        left[i] = 0.95f;
        right[i] = 0.95f;
    }
    const float inputPeak = peakAbs(left, right, kFrames);

    audioapp::CompressorParams compParams;
    compParams.compThreshold = 0.35f;
    compParams.compRatio = 0.75f;
    compParams.compKnee = 0.0f;
    compParams.compMakeup = 0.0f;
    audioapp::DynamicsRuntime compRuntime{};
    audioapp::processCompressorStereoBlock(left, right, kFrames, kSampleRate, compParams, compRuntime);

    if (peakAbs(left, right, kFrames) >= inputPeak * 0.98f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
