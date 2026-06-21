#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/SnareGenerator.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"

#include <cmath>
#include <cstring>

class SnareGeneratorTest : public juce::UnitTest {
public:
    SnareGeneratorTest() : juce::UnitTest("SnareGenerator", "Audio") {}

    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        audioapp::MidiPlaybackNote notes[1] = {
            {38, 0.0, 4.0, 0.0, 1.0, 100.0f},
        };

        audioapp::DeviceNodePlayback devices[1] = {};
        devices[0].kind = audioapp::DeviceNodeKind::SnareGenerator;
        devices[0].gain = 1.0f;
        devices[0].pan = 0.5f;
        devices[0].params = audioapp::SnareGeneratorParams{};

        beginTest("device chain produces output");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));
            float phase = 0.0f;
            audioapp::SnareGeneratorRuntime runtime{};

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
                                         &runtime,
                                         nullptr,
                                         nullptr);

            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Snare device chain should produce audible output");
        }

        beginTest("live performance mixer");
        {
            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::SnareGenerator;
            instrument.gain = 1.0f;
            instrument.snare.gain = 1.0f;

            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 38, 100.0f);

            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Snare live performance mixer should produce audible output");
        }
    }
};

static SnareGeneratorTest snareGeneratorTest;
