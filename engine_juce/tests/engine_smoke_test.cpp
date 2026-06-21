#include <juce_core/juce_core.h>
#include "TestHelpers.h"
#include "audioapp/EngineHost.hpp"
#include "audioapp/TestOscillator.hpp"

class EngineSmokeTest : public juce::UnitTest {
public:
    EngineSmokeTest() : juce::UnitTest("EngineSmoke", "Engine") {}
    void runTest() override {
        beginTest("ping");
        {
            audioapp::EngineHost host;
            expect(host.ping() == "pong", "ping should return pong");
        }
        beginTest("oscillator");
        {
            audioapp::TestOscillator osc;
            osc.setFrequency(440.0f);
            osc.setEnabled(true);

            constexpr int numSamples = 512;
            constexpr double sampleRate = 48000.0;
            std::vector<float> buffer(numSamples);
            osc.processBlock(buffer.data(), numSamples, sampleRate);

            float sumSquares = 0.0f;
            for (float s : buffer)
                sumSquares += s * s;
            const float rms = std::sqrt(sumSquares / static_cast<float>(numSamples));
            expect(rms >= 0.01f, "oscillator RMS should be audible");
        }
    }
};
static EngineSmokeTest engineSmokeTest;