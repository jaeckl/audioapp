#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cmath>
#include <cstring>

class KickGeneratorTest : public juce::UnitTest {
public:
    KickGeneratorTest() : juce::UnitTest("KickGenerator", "Audio") {}

    void runTest() override {
        constexpr int kFrames = 2048;
        constexpr double kSampleRate = 48000.0;

        audioapp::MidiPlaybackNote notes[1] = {
            {36, 0.0, 4.0, 0.0, 1.0, 100.0f},
        };

        audioapp::DeviceNodePlayback devices[1] = {};
        devices[0].kind = audioapp::DeviceNodeKind::KickGenerator;
        devices[0].gain = 1.0f;
        devices[0].pan = 0.5f;
        devices[0].params = audioapp::KickGeneratorParams{};

        beginTest("device chain with default params");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);

            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Kick device chain with default params should produce audible output");
        }

        beginTest("device chain with kickModel=0.5f");
        {
            auto& kickParams = std::get<audioapp::KickGeneratorParams>(devices[0].params);
            kickParams.kickModel = 0.5f;

            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);

            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Kick device chain with kickModel=0.5f should produce audible output");
        }

        beginTest("live performance mixer");
        {
            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::KickGenerator;
            instrument.gain = 1.0f;
            instrument.kick.gain = 1.0f;

            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 36, 100.0f);

            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Kick live performance mixer should produce audible output");
        }
    }
};

static KickGeneratorTest kickGeneratorTest;
