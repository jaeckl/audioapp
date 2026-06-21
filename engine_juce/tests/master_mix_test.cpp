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
    }
};
static MasterMixTest masterMixTest;