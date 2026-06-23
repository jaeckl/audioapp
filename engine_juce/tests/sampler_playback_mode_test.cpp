#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/SamplePlayback.hpp"

class SamplerPlaybackModeTest : public juce::UnitTest {
public:
    SamplerPlaybackModeTest() : juce::UnitTest("SamplerPlaybackMode", "Engine") {}
    void runTest() override {
        using namespace audioapp;

        beginTest("one-shot forward at start");
        {
            double readPos = 0.0;
            expect(computeSamplerReadPosition(0, 100, 1000, 0, 0, 0.0, 48000.0, 1.0, readPos),
                   "one-shot forward returns true");
            expectWithinAbsoluteError(readPos, 100.0, 0.01);
        }
        beginTest("one-shot ends after trim window");
        {
            double readPos = 0.0;
            expect(!computeSamplerReadPosition(0, 100, 200, 0, 0, 1.0, 48000.0, 1.0, readPos),
                   "one-shot ends after trim window");
        }
        beginTest("loop wraps inside region");
        {
            double readPos = 0.0;
            expect(computeSamplerReadPosition(1, 0, 1000, 200, 400, 0.5, 48000.0, 1.0, readPos),
                   "loop returns true");
            expect(readPos >= 200.0 && readPos < 400.0, "loop wraps inside 200..400");
        }
        beginTest("reverse moves backward from trim end");
        {
            double readPos = 0.0;
            expect(computeSamplerReadPosition(2, 100, 500, 0, 0, 0.0, 48000.0, 1.0, readPos),
                   "reverse returns true");
            expectWithinAbsoluteError(readPos, 499.0, 0.01);
        }
        beginTest("pitch ratio with fine tune");
        {
            const double oneSemitone = std::pow(2.0, 1.0 / 12.0);
            expectWithinAbsoluteError(samplerPitchRatio(60, 60, 100.0f),
                                      oneSemitone, 1.0e-6);
            expectWithinAbsoluteError(samplerPitchRatio(60, 60, 0.0f),
                                      1.0, 1.0e-6);
            expectWithinAbsoluteError(samplerPitchRatio(72, 60, 0.0f),
                                      2.0, 1.0e-6);
        }
        beginTest("filter cutoff modulation");
        {
            const float baseCutoff = samplerFilterCutoffHz(0.5f, 0.0f, 1.0f);
            const float modCutoff = samplerFilterCutoffHz(0.5f, 1.0f, 0.5f);
            expect(modCutoff > baseCutoff, "modulated cutoff > base cutoff");
        }
    }
};
static SamplerPlaybackModeTest samplerPlaybackModeTest;