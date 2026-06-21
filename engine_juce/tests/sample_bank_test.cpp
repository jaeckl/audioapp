#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/SampleBank.hpp"

class SampleBankTest : public juce::UnitTest {
public:
    SampleBankTest() : juce::UnitTest("SampleBank", "Engine") {}
    void runTest() override {
        beginTest("sample bank defaults");
        {
            audioapp::SampleBank bank;
            bank.registerBundledDefaults();
            const auto samples = bank.listSamples();
            expect(samples.size() >= 4, "at least 4 bundled samples");
            expect(bank.findSample("sample_kick") != nullptr, "sample_kick found");
            expect(bank.beatsForSample("sample_kick", 120) > 0.0,
                   "sample_kick beatsForSample positive");
        }
    }
};
static SampleBankTest sampleBankTest;