#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"

#include <cstring>

class DeviceChainTest : public juce::UnitTest {
public:
    DeviceChainTest() : juce::UnitTest("DeviceChain", "Devices") {}

    void runTest() override
    {
        constexpr int kFrames = 256;
        constexpr double kSampleRate = 48000.0;
        float left[kFrames];
        float right[kFrames];

        beginTest("sampler without PCM stays silent");
        {
            audioapp::MidiPlaybackNote notes[1] = {
                {60, 0.0, 4.0, 0.0, 1.0, 100.0f},
            };
            audioapp::DeviceNodePlayback devices[1] = {};
            devices[0].kind = audioapp::DeviceNodeKind::Sampler;
            devices[0].gain = 1.0f;
            devices[0].pan = 0.5f;
            devices[0].params = audioapp::SamplerParams{};

            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            float phase = 0.0f;
            audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0,
                                         notes, 1, devices, 1, phase, false);
            expect(audioapp::test::peakAbs(left, kFrames) <= 1.0e-6f,
                   "sampler without PCM should produce silence (left)");
            expect(audioapp::test::peakAbs(right, kFrames) <= 1.0e-6f,
                   "sampler without PCM should produce silence (right)");
        }

        beginTest("oscillator generates audio, track gain scales");
        {
            audioapp::DeviceNodePlayback devices[2] = {};
            devices[0].kind = audioapp::DeviceNodeKind::Oscillator;
            devices[0].gain = 1.0f;
            devices[0].pan = 0.5f;
            devices[0].params = audioapp::OscillatorParams{440.0f};
            devices[1].kind = audioapp::DeviceNodeKind::TrackGain;
            devices[1].gain = 0.25f;
            devices[1].params = audioapp::TrackGainParams{};

            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            float phase = 0.0f;
            audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0,
                                         nullptr, 0, devices, 2, phase, false);
            const float peak = (audioapp::test::peakAbs(left, kFrames) +
                                audioapp::test::peakAbs(right, kFrames)) * 0.5f;
            expect(peak > 0.01f, "oscillator should produce non-trivial output");
            expect(peak < audioapp::kInstrumentOutputGain * 0.9f,
                   "track gain should scale oscillator output");
        }

        beginTest("hard pan left biases energy left");
        {
            audioapp::DeviceNodePlayback devices[1] = {};
            devices[0].kind = audioapp::DeviceNodeKind::Oscillator;
            devices[0].gain = 1.0f;
            devices[0].pan = 0.0f;
            devices[0].params = audioapp::OscillatorParams{440.0f};

            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            float phase = 0.0f;
            audioapp::processDeviceChain(left, right, kFrames, kSampleRate, 120, 0.0,
                                         nullptr, 0, devices, 1, phase, false);
            expect(audioapp::test::peakAbs(left, kFrames) > audioapp::test::peakAbs(right, kFrames),
                   "left channel should have more energy when panned left");
        }

        beginTest("engine integration: default track is sampler-only");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Sampler");
            expect(!trackId.empty(), "should create track");

            float buffer[kFrames];
            host.setPlaying(true);
            std::memset(buffer, 0, sizeof(buffer));
            host.readMasterMix(buffer, kFrames, kSampleRate, 0.0);
            expect(audioapp::test::peakAbs(buffer, kFrames) <= 1.0e-4f,
                   "default sampler-only track should produce silence");
        }
    }
};

static DeviceChainTest deviceChainTest;