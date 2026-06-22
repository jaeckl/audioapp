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
    }
};

static CymbalGeneratorTest cymbalGeneratorTest;
