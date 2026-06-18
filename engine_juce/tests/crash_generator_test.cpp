#include "audioapp/DeviceChain.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/LivePerformance.hpp"

#include <cmath>
#include <cstdlib>
#include <cstring>

namespace {

float peakAbs(const float* buffer, int count) {
    float peak = 0.0f;
    for (int i = 0; i < count; ++i) {
        peak = std::max(peak, std::abs(buffer[i]));
    }
    return peak;
}

} // namespace

int main() {
    constexpr int kFrames = 4096;
    constexpr double kSampleRate = 48000.0;

    audioapp::MidiPlaybackNote notes[1] = {
        {49, 0.0, 4.0, 0.0, 1.0, 100.0f},
    };

    audioapp::DeviceNodePlayback devices[1] = {};
    devices[0].kind = audioapp::DeviceNodeKind::CrashGenerator;
    devices[0].gain = 1.0f;
    devices[0].pan = 0.5f;
    devices[0].params = audioapp::CrashGeneratorParams{};

    float left[kFrames];
    float right[kFrames];
    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));
    float phase = 0.0f;
    audioapp::CrashGeneratorRuntime runtime{};

    audioapp::processDeviceChain(left,
                                 right,
                                 kFrames,
                                 kSampleRate,
                                 120,
                                 0.0,
                                 notes,
                                 1,
                                 devices,
                                 1,
                                 phase,
                                 false,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 &runtime);

    if (peakAbs(left, kFrames) <= 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::LiveInstrumentSnapshot instrument{};
    instrument.kind = audioapp::LiveInstrumentKind::CrashGenerator;
    instrument.gain = 1.0f;
    instrument.crash.gain = 1.0f;

    audioapp::LivePerformanceMixer mixer;
    mixer.noteOn(instrument, 49, 100.0f);

    float live[kFrames];
    std::memset(live, 0, sizeof(live));
    mixer.readMix(live, kFrames, kSampleRate);
    if (peakAbs(live, kFrames) <= 0.001f) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
