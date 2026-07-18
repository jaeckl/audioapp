#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cmath>
#include <cstring>

class CrashGeneratorTest : public juce::UnitTest {
public:
    CrashGeneratorTest() : juce::UnitTest("CrashGenerator", "Audio") {}

    void runTest() override {
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

        beginTest("device chain produces output");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);

            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Crash device chain should produce audible output");
        }

        beginTest("live performance mixer");
        {
            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::CrashGenerator;
            instrument.gain = 1.0f;
            instrument.crash.gain = 1.0f;

            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 49, 100.0f);

            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Crash live performance mixer should produce audible output");
        }

        beginTest("pitch changes crash spectrum");
        {
            audioapp::CrashGeneratorParams lowParams;
            auto highParams = lowParams;
            lowParams.crashPitch = 0.25f;
            highParams.crashPitch = 0.75f;
            audioapp::CrashVoiceRuntime low;
            audioapp::CrashVoiceRuntime high;
            audioapp::triggerCrashVoice(low, 49, 100.0f);
            audioapp::triggerCrashVoice(high, 49, 100.0f);
            float difference = 0.0f;
            for (int frame = 0; frame < 512; ++frame) {
                low.elapsedSec = high.elapsedSec = frame / kSampleRate;
                const float lowSample = audioapp::crashGeneratorSampleL(
                    low, lowParams, kSampleRate, 1.0f);
                const float highSample = audioapp::crashGeneratorSampleL(
                    high, highParams, kSampleRate, 1.0f);
                difference += std::abs(lowSample - highSample);
            }
            expect(difference > 0.01f, "crash pitch should change rendered audio");
        }
    }
};

static CrashGeneratorTest crashGeneratorTest;
