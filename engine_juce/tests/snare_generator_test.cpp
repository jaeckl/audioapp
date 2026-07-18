#include "audioapp/DeviceChain.hpp"
#include "audioapp/LivePerformance.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

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

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 1, devices, 1, false);

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

        beginTest("pitch and keytrack control membrane tuning");
        {
            audioapp::SnareGeneratorParams params;
            audioapp::SnareVoiceRuntime low;
            audioapp::SnareVoiceRuntime high;
            params.snareTune = 0.25f;
            audioapp::triggerSnareVoice(low, 38, 100.0f);
            audioapp::configureSnareVoice(low, params, kSampleRate);
            params.snareTune = 0.75f;
            audioapp::triggerSnareVoice(high, 38, 100.0f);
            audioapp::configureSnareVoice(high, params, kSampleRate);
            expect(high.membraneHz[0] > low.membraneHz[0] * 3.5f,
                   "snare pitch should span four octaves");

            params.snareTune = 0.5f;
            params.snareKeyTrack = 0.0f;
            audioapp::triggerSnareVoice(low, 38, 100.0f);
            audioapp::triggerSnareVoice(high, 50, 100.0f);
            audioapp::configureSnareVoice(low, params, kSampleRate);
            audioapp::configureSnareVoice(high, params, kSampleRate);
            expectWithinAbsoluteError(high.membraneHz[0], low.membraneHz[0], 0.001f,
                                      "disabled keytrack should ignore MIDI pitch");
        }
    }
};

static SnareGeneratorTest snareGeneratorTest;
