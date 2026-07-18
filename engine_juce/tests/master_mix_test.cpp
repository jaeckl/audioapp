#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"

class MasterMixTest : public juce::UnitTest {
public:
    MasterMixTest() : juce::UnitTest("MasterMix", "Engine") {}
    void runTest() override {
        beginTest("master mix produces audio");
        {
            audioapp::EngineHost host;
            host.createProject();
            const std::string trackA = host.addTrack("A");
            const std::string trackB = host.addTrack("B");
            expect(!trackA.empty(), "trackA id non-empty");
            expect(!trackB.empty(), "trackB id non-empty");

            expect(!host.createSampleClip(trackA, "sample_kick", 0.0, 0.0).empty(),
                   "createSampleClip trackA");
            expect(!host.createSampleClip(trackB, "sample_snare", 0.0, 0.0).empty(),
                   "createSampleClip trackB");

            host.setPlaying(true);

            float buffer[256] = {};
            host.readMasterMix(buffer, 256, 48000.0, 0.0);

            float peak = 0.0f;
            for (const float sample : buffer)
                peak = std::max(peak, std::abs(sample));
            expect(peak > 0.0f, "master mix should produce non-zero audio");
        }

        beginTest("live master gain ramps inside the callback");
        {
            audioapp::EngineHost host;
            host.createProject();
            const auto track = host.addTrack("Ramp");
            host.selectTrack(track);
            host.addDeviceToTrack(track, "simple_oscillator");
            const auto clip = host.createMidiClip(track, 0.0, 4.0);
            host.setMidiClipNotes(clip, {{69, 0.0, 4.0, 100.0f}});
            host.setPlaying(true);

            float buffer[128]{};
            host.setMasterGain(0.0f);
            host.readMasterMix(buffer, 128, 48000.0, 0.0);
            host.readMasterMix(buffer, 128, 48000.0, 128.0 / 24000.0);
            host.setMasterGain(1.0f);
            host.readMasterMix(buffer, 128, 48000.0, 256.0 / 24000.0);

            float latePeak = 0.0f;
            for (int frame = 96; frame < 128; ++frame)
                latePeak = std::max(latePeak, std::abs(buffer[frame]));
            expect(std::abs(buffer[0]) < 0.01f,
                   "first sample stays near the prior silent master value");
            expect(latePeak > 0.02f,
                   "master ramp reaches audible gain later in the block");
        }
    }
};
static MasterMixTest masterMixTest;
