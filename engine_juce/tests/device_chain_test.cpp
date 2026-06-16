#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"

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
    constexpr int kFrames = 256;
    constexpr double kSampleRate = 48000.0;
    float buffer[kFrames];

    // Sampler node without loaded PCM stays silent even with MIDI notes present.
    {
        audioapp::MidiPlaybackNote notes[1] = {
            {60, 0.0, 4.0, 0.0, 1.0, 100.0f},
        };
        audioapp::DeviceNodePlayback devices[1] = {};
        devices[0].kind = audioapp::DeviceNodeKind::Sampler;
        devices[0].gain = 1.0f;

        std::memset(buffer, 0, sizeof(buffer));
        float phase = 0.0f;
        audioapp::processDeviceChain(buffer,
                                     kFrames,
                                     kSampleRate,
                                     120,
                                     0.0,
                                     notes,
                                     1,
                                     devices,
                                     1,
                                     phase,
                                     false);
        if (peakAbs(buffer, kFrames) > 1.0e-6f) {
            return EXIT_FAILURE;
        }
    }

    // Oscillator node generates audio; track_gain scales it down.
    {
        audioapp::DeviceNodePlayback devices[2] = {};
        devices[0].kind = audioapp::DeviceNodeKind::Oscillator;
        devices[0].frequencyHz = 440.0f;
        devices[1].kind = audioapp::DeviceNodeKind::TrackGain;
        devices[1].gain = 0.25f;

        std::memset(buffer, 0, sizeof(buffer));
        float phase = 0.0f;
        audioapp::processDeviceChain(buffer,
                                     kFrames,
                                     kSampleRate,
                                     120,
                                     0.0,
                                     nullptr,
                                     0,
                                     devices,
                                     2,
                                     phase,
                                     false);
        const float peak = peakAbs(buffer, kFrames);
        if (peak <= 0.01f) {
            return EXIT_FAILURE;
        }
        if (peak >= audioapp::kInstrumentOutputGain * 0.9f) {
            return EXIT_FAILURE;
        }
    }

    // Engine integration: default track is sampler-only; no sine unless oscillator device exists.
    {
        audioapp::EngineHost host;
        host.createProject();
        const std::string trackId = host.addTrack("Sampler");
        if (trackId.empty()) {
            return EXIT_FAILURE;
        }

        host.setPlaying(true);
        std::memset(buffer, 0, sizeof(buffer));
        host.readMasterMix(buffer, kFrames, kSampleRate, 0.0);
        if (peakAbs(buffer, kFrames) > 1.0e-4f) {
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
