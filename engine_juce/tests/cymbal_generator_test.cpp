#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cmath>
#include <cstring>

class CymbalGeneratorTest : public juce::UnitTest {
public:
    CymbalGeneratorTest() : juce::UnitTest("CymbalGenerator", "Audio") {}

    void runTest() override {
        constexpr int kFrames = 4096;
        constexpr double kSampleRate = 48000.0;

        audioapp::MidiPlaybackNote notes[1] = {
            {42, 0.0, 4.0, 0.0, 1.0, 100.0f},
        };

        audioapp::DeviceNodePlayback devices[1] = {};
        devices[0].kind = audioapp::DeviceNodeKind::CymbalGenerator;
        devices[0].gain = 1.0f;
        devices[0].pan = 0.5f;
        devices[0].params = audioapp::CymbalGeneratorParams{};

        beginTest("device chain produces output");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);

            expect(audioapp::test::peakAbs(left, kFrames) > 0.001f,
                   "Cymbal device chain should produce audible output");
        }

        beginTest("live performance mixer");
        {
            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::CymbalGenerator;
            instrument.gain = 1.0f;
            instrument.cymbal.gain = 1.0f;

            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 42, 100.0f);

            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Cymbal live performance mixer should produce audible output");
        }

        beginTest("pitch changes cymbal spectrum");
        {
            audioapp::CymbalGeneratorParams lowParams;
            auto highParams = lowParams;
            lowParams.cymbalPitch = 0.25f;
            highParams.cymbalPitch = 0.75f;
            audioapp::CymbalVoiceRuntime low;
            audioapp::CymbalVoiceRuntime high;
            audioapp::triggerCymbalVoice(low, 42, 100.0f);
            audioapp::triggerCymbalVoice(high, 42, 100.0f);
            float difference = 0.0f;
            for (int frame = 0; frame < 512; ++frame) {
                low.elapsedSec = high.elapsedSec = frame / kSampleRate;
                const float lowSample = audioapp::cymbalGeneratorSampleL(
                    low, lowParams, kSampleRate, 1.0f);
                const float highSample = audioapp::cymbalGeneratorSampleL(
                    high, highParams, kSampleRate, 1.0f);
                difference += std::abs(lowSample - highSample);
            }
            expect(difference > 0.01f, "cymbal pitch should change rendered audio");
        }
    }
};

static CymbalGeneratorTest cymbalGeneratorTest;
