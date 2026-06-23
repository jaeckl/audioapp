#include "audioapp/DeviceChain.hpp"
#include "audioapp/EngineHost.hpp"
#include "audioapp/LivePerformance.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "TestChainHelper.hpp"

#include <cmath>
#include <cstring>

class SubtractiveSynthTest : public juce::UnitTest {
public:
    SubtractiveSynthTest() : juce::UnitTest("SubtractiveSynth", "Audio") {}

    void runTest() override {
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
        {
            audioapp::SubtractiveSynthParams synthParams;
            synthParams.gain = 1.0f;
            synthParams.osc1Shape = 0.5f;
            synthParams.filterCutoff = 0.7f;
            devices[0].params = synthParams;
        }

        beginTest("device chain produces output");
        {
            float left[kFrames];
            float right[kFrames];
            std::memset(left, 0, sizeof(left));
            std::memset(right, 0, sizeof(right));

            audioapp::test::processTestChain(left, right, kFrames, kSampleRate, 120, 0.0, notes, 3, devices, 1, false);

            const float peak =
                (audioapp::test::peakAbs(left, kFrames) + audioapp::test::peakAbs(right, kFrames)) * 0.5f;
            expect(peak > 0.001f, "Subtractive synth device chain should produce audible output");
        }

        beginTest("engine host project JSON");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackId = host.addTrack("Synth");
            const std::string deviceId = host.addDeviceToTrack(trackId, "subtractive_synth");
            expect(!deviceId.empty(), "addDeviceToTrack should return non-empty device ID");

            audioapp::LiveInstrumentSnapshot instrument{};
            instrument.kind = audioapp::LiveInstrumentKind::SubtractiveSynth;
            instrument.gain = 1.0f;
            instrument.subtractive.gain = 1.0f;
            instrument.subtractive.osc1Shape = 0.5f;

            audioapp::LivePerformanceMixer mixer;
            mixer.noteOn(instrument, 60, 100.0f);

            float live[kFrames];
            std::memset(live, 0, sizeof(live));
            mixer.readMix(live, kFrames, kSampleRate);
            expect(audioapp::test::peakAbs(live, kFrames) > 0.001f,
                   "Live performance mixer should produce audible output");

            const std::string json = host.getProjectFileJson();
            expect(json.find("subtractive_synth") != std::string::npos,
                   "Project JSON should contain device type 'subtractive_synth'");
        }
    }
};

static SubtractiveSynthTest subtractiveSynthTest;