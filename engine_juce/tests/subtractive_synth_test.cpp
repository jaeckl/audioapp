#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/SubtractiveSynth.hpp"

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
    constexpr int kFrames = 2048;
    constexpr double kSampleRate = 48000.0;

    audioapp::MidiPlaybackNote notes[3] = {
        {60, 0.0, 4.0, 0.0, 2.0, 100.0f},
        {64, 0.0, 4.0, 0.0, 2.0, 100.0f},
        {67, 0.0, 4.0, 0.0, 2.0, 100.0f},
    };

    audioapp::DeviceNodePlayback devices[1] = {};
    devices[0].kind = audioapp::DeviceNodeKind::SubtractiveSynth;
    devices[0].gain = 1.0f;
    devices[0].pan = 0.5f;
    devices[0].subtractive.gain = 1.0f;
    devices[0].subtractive.osc1Wave = 2;
    devices[0].subtractive.filterCutoff = 0.7f;

    float left[kFrames];
    float right[kFrames];
    std::memset(left, 0, sizeof(left));
    std::memset(right, 0, sizeof(right));
    float phase = 0.0f;
    audioapp::SubtractiveSynthRuntime runtime{};

    audioapp::processDeviceChain(left,
                                 right,
                                 kFrames,
                                 kSampleRate,
                                 120,
                                 0.0,
                                 notes,
                                 3,
                                 devices,
                                 1,
                                 phase,
                                 false,
                                 nullptr,
                                 &runtime);

    const float peak = (peakAbs(left, kFrames) + peakAbs(right, kFrames)) * 0.5f;
    if (peak <= 0.001f) {
        return EXIT_FAILURE;
    }

    audioapp::EngineHost host;
    host.createProject();
    const std::string trackId = host.addTrack("Synth");
    const std::string deviceId = host.addDeviceToTrack(trackId, "subtractive_synth");
    if (deviceId.empty()) {
        return EXIT_FAILURE;
    }

    audioapp::LiveInstrumentSnapshot instrument{};
    instrument.kind = audioapp::LiveInstrumentKind::SubtractiveSynth;
    instrument.gain = 1.0f;
    instrument.subtractive.gain = 1.0f;
    instrument.subtractive.osc1Wave = 2;

    audioapp::LivePerformanceMixer mixer;
    mixer.noteOn(instrument, 60, 100.0f);

    float live[kFrames];
    std::memset(live, 0, sizeof(live));
    mixer.readMix(live, kFrames, kSampleRate);
    if (peakAbs(live, kFrames) <= 0.001f) {
        return EXIT_FAILURE;
    }

    const std::string json = host.getProjectFileJson();
    if (json.find("subtractive_synth") == std::string::npos) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
