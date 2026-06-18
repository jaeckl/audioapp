#include "audioapp/DeviceChain.hpp"
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

    audioapp::DeviceNodePlayback osc{};
    osc.kind = audioapp::DeviceNodeKind::Oscillator;
    osc.gain = 1.0f;
    osc.pan = 0.5f;
    osc.params = audioapp::OscillatorParams{440.0f};

    float left[kFrames];
    float right[kFrames];
    float phase = 0.0f;
    audioapp::DynamicsRuntime dynamicsRuntimes[audioapp::kMaxDevicesPerTrack] = {};

    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));
    audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, &osc, 1,
                                 phase, false);

    const float peakOscOnly = peakAbs(left, right, kFrames);
    if (peakOscOnly <= 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::DeviceNodePlayback gate{};
    gate.kind = audioapp::DeviceNodeKind::Gate;
    gate.gain = 1.0f;
    gate.pan = 0.5f;
    audioapp::GateParams closedGate;
    closedGate.gateThreshold = 0.95f;
    closedGate.gateRange = 0.0f;
    gate.params = closedGate;

    audioapp::DeviceNodePlayback chain[2] = {osc, gate};
    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));

    audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, chain, 2,
                                 phase, false, nullptr, nullptr, nullptr, nullptr, nullptr,
                                 nullptr, dynamicsRuntimes);

    if (peakAbs(left, right, kFrames) >= peakOscOnly * 0.25f) {
        return EXIT_FAILURE;
    }

    audioapp::GateParams openGate;
    openGate.gateThreshold = 0.0f;
    openGate.gateRange = 1.0f;
    chain[1].params = openGate;
    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));
    std::memset(dynamicsRuntimes, 0, sizeof(dynamicsRuntimes));

    audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0, nullptr, 0, chain, 2,
                                 phase, false, nullptr, nullptr, nullptr, nullptr, nullptr,
                                 nullptr, dynamicsRuntimes);

    if (peakAbs(left, right, kFrames) < peakOscOnly * 0.5f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
